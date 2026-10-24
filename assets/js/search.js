/**
 * EipSearch — shared search engine for the EIPs website.
 *
 * Modes:
 *   - dropdown  (header): shows top 5 results + "View all" link
 *   - page      (/search/): shows full paginated results, reads ?q= from URL
 */
(function () {
  'use strict';

  /* ------------------------------------------------------------------ */
  /*  Shared search primitives                                           */
  /* ------------------------------------------------------------------ */

  var searchIndex = [];
  var baseurl = window.EIP_BASEURL || '';
  var indexLoadFailed = false;

  function loadIndex() {
    if (searchIndex.length > 0 || indexLoadFailed) return;
    fetch(baseurl + '/search-index.json')
      .then(function (r) { return r.json(); })
      .then(function (data) { searchIndex = data; })
      .catch(function () { indexLoadFailed = true; });
  }

  function debounce(fn, ms) {
    var timer;
    return function () { clearTimeout(timer); timer = setTimeout(fn, ms); };
  }

  function tokenize(text) {
    return (text || '').toLowerCase()
      .replace(/[^a-z0-9\s-]/g, ' ')
      .split(/\s+/)
      .filter(Boolean);
  }

  function scoreDocument(doc, queryTokens) {
    var score = 0;
    var titleStr = (doc.title || '').toLowerCase();
    var descStr = (doc.description || '').toLowerCase();
    var contentStr = (doc.content || '').toLowerCase();
    var statusStr = (doc.status || '').toLowerCase();
    var typeStr = (doc.type || '').toLowerCase();
    var categoryStr = (doc.category || '').toLowerCase();
    var authorStr = (doc.author || '').toLowerCase();
    var eipStr = String(doc.eip || '');
    var titleWords = titleStr.split(/\s+/);

    for (var t = 0; t < queryTokens.length; t++) {
      var qt = queryTokens[t];

      if (eipStr === qt || eipStr.indexOf(qt) !== -1) { score += 50; }

      if (titleStr.indexOf(qt) !== -1) {
        score += 25;
        if (titleWords.indexOf(qt) !== -1) {
          score += 15;
          if (titleWords[0] === qt) score += 10;
        }
        for (var w = 0; w < titleWords.length; w++) {
          if (titleWords[w].length > qt.length && titleWords[w].indexOf(qt) === 0) {
            score += 5; break;
          }
        }
      }

      if (descStr.indexOf(qt) !== -1) { score += 8; }

      if (contentStr.indexOf(qt) !== -1) {
        var count = 0, pos = -1;
        while ((pos = contentStr.indexOf(qt, pos + 1)) !== -1) { count++; }
        score += 4 + Math.min(count, 6);
      }

      if (statusStr.indexOf(qt) !== -1)   score += 6;
      if (typeStr.indexOf(qt) !== -1 || categoryStr.indexOf(qt) !== -1) score += 5;
      if (authorStr.indexOf(qt) !== -1)   score += 4;
    }

    var titleMatchCount = 0;
    for (var tt = 0; tt < queryTokens.length; tt++) {
      if (titleStr.indexOf(queryTokens[tt]) !== -1) titleMatchCount++;
    }
    if (queryTokens.length > 1 && titleMatchCount > 1) score += titleMatchCount * 8;

    var allText = [titleStr, descStr, contentStr, statusStr, typeStr, categoryStr, authorStr, eipStr].join(' ');
    if (queryTokens.length > 1 && allText.indexOf(queryTokens.join(' ')) !== -1) score += 15;

    return score;
  }

  function search(query) {
    query = (query || '').trim();
    if (query.length < 2 || searchIndex.length === 0) return [];
    var tokens = tokenize(query);
    if (tokens.length === 0) return [];

    var results = [];
    for (var i = 0; i < searchIndex.length; i++) {
      var doc = searchIndex[i];
      var s = scoreDocument(doc, tokens);
      if (s > 0) results.push({ doc: doc, score: s });
    }
    results.sort(function (a, b) { return b.score - a.score; });
    return { results: results, tokens: tokens, query: query };
  }

  /* ------------------------------------------------------------------ */
  /*  Rendering helpers                                                  */
  /* ------------------------------------------------------------------ */

  function highlightText(text, tokens) {
    if (!text || !tokens || tokens.length === 0) return text || '';
    var out = text;
    for (var t = 0; t < tokens.length; t++) {
      out = out.replace(new RegExp('(' + tokens[t].replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + ')', 'gi'), '<mark>$1</mark>');
    }
    return out;
  }

  function extractContextSnippet(content, tokens) {
    if (!content || !tokens || tokens.length === 0) return '';
    var lower = content.toLowerCase();
    var firstPos = -1, matchLen = 0;
    for (var t = 0; t < tokens.length; t++) {
      var p = lower.indexOf(tokens[t]);
      if (p !== -1 && (firstPos === -1 || p < firstPos)) { firstPos = p; matchLen = tokens[t].length; }
    }
    if (firstPos === -1) return '';

    var ctx = 120;
    var start = Math.max(0, firstPos - ctx);
    if (start > 0) {
      var sp = content.indexOf(' ', start);
      if (sp !== -1 && sp < firstPos) start = sp + 1;
    }
    var end = Math.min(content.length, firstPos + matchLen + ctx);
    if (end < content.length) {
      var sa = content.indexOf(' ', end);
      if (sa !== -1 && sa - end < 40) end = sa;
    }
    var snippet = content.substring(start, end).trim();
    if (start > 0) snippet = '…' + snippet;
    if (end < content.length) snippet = snippet + '…';
    return snippet;
  }

  function escapeHtml(str) {
    if (!str) return '';
    var d = document.createElement('div');
    d.textContent = str;
    return d.innerHTML;
  }

  function getStatusBadge(status) {
    if (!status) return '';
    var colors = {
      'Final': '#198754', 'Living': '#198754', 'Last Call': '#0d6efd',
      'Review': '#ffc107', 'Draft': '#6c757d', 'Stagnant': '#dc3545', 'Withdrawn': '#dc3545'
    };
    return '<span class="eip-search__badge" style="background-color:' + (colors[status] || '#6c757d') + '">' + escapeHtml(status) + '</span>';
  }

  function resultHtml(doc, tokens) {
    var snippet = extractContextSnippet(doc.content, tokens);
    var snippetHtml = snippet
      ? highlightText(snippet, tokens)
      : highlightText(doc.description, tokens);
    var typeLabel = doc.type || '';
    if (doc.category) typeLabel += ' · ' + doc.category;

    return '<a href="' + doc.url + '" class="eip-search__result">' +
      '<div class="eip-search__result-header">' +
        '<span class="eip-search__result-number">EIP-' + doc.eip + '</span>' +
        getStatusBadge(doc.status) +
      '</div>' +
      '<div class="eip-search__result-title">' + highlightText(doc.title, tokens) + '</div>' +
      '<div class="eip-search__result-desc">' + snippetHtml + '</div>' +
      '<div class="eip-search__result-meta">' + escapeHtml(typeLabel) + '</div>' +
    '</a>';
  }

  /* ------------------------------------------------------------------ */
  /*  Header dropdown mode                                               */
  /* ------------------------------------------------------------------ */

  (function initDropdown() {
    var input = document.getElementById('eip-search-input');
    var container = document.getElementById('eip-search-container');
    var resultsEl = document.getElementById('eip-search-results');
    if (!input || !resultsEl) return;

    loadIndex();

    function renderDropdown(data) {
      if (!resultsEl) return;
      if (!data || data.results.length === 0) {
        resultsEl.innerHTML = '<div class="eip-search__empty">No EIPs found matching "' + escapeHtml(input.value) + '"</div>';
        resultsEl.classList.add('eip-search__results--visible');
        return;
      }

      var html = '<div class="eip-search__results-count">' + data.results.length + ' result' + (data.results.length !== 1 ? 's' : '') + '</div>';
      var count = Math.min(5, data.results.length);
      for (var i = 0; i < count; i++) {
        html += resultHtml(data.results[i].doc, data.tokens);
      }
      html += '<a href="' + baseurl + '/search/?q=' + encodeURIComponent(data.query) + '" class="eip-search__view-all">View all ' + data.results.length + ' results →</a>';
      resultsEl.innerHTML = html;
      resultsEl.classList.add('eip-search__results--visible');
    }

    var onInput = debounce(function () {
      renderDropdown(search(input.value));
    }, 200);

    input.addEventListener('input', onInput);

    input.addEventListener('keydown', function (e) {
      if (e.key === 'ArrowDown' || e.key === 'ArrowUp') {
        e.preventDefault();
        var items = resultsEl.querySelectorAll('.eip-search__result');
        if (items.length === 0) return;
        var idx = Array.prototype.indexOf.call(items, document.activeElement);
        var next = e.key === 'ArrowDown'
          ? (idx < items.length - 1 ? idx + 1 : 0)
          : (idx > 0 ? idx - 1 : items.length - 1);
        items[next].focus();
      }
      if (e.key === 'Escape') {
        resultsEl.classList.remove('eip-search__results--visible');
        input.blur();
      }
    });

    document.addEventListener('click', function (e) {
      if (container && !container.contains(e.target)) {
        resultsEl.classList.remove('eip-search__results--visible');
      }
    });

    input.addEventListener('focus', function () {
      if (this.value.trim().length >= 2 && searchIndex.length > 0) {
        renderDropdown(search(this.value));
      }
    });

    // Pressing Enter in the header input navigates to the full search page
    input.addEventListener('keydown', function (e) {
      if (e.key === 'Enter') {
        var q = this.value.trim();
        if (q.length >= 2) {
          window.location.href = baseurl + '/search/?q=' + encodeURIComponent(q);
        }
      }
    });

    // Support up/down arrow at the bottom of the dropdown to wrap to "View all"
    resultsEl.addEventListener('keydown', function (e) {
      if (e.key === 'ArrowDown' || e.key === 'ArrowUp') {
        var items = resultsEl.querySelectorAll('.eip-search__result, .eip-search__view-all');
        if (items.length === 0) return;
        var idx = Array.prototype.indexOf.call(items, document.activeElement);
        var next;
        if (e.key === 'ArrowDown') {
          next = idx < items.length - 1 ? idx + 1 : 0;
        } else {
          next = idx > 0 ? idx - 1 : items.length - 1;
        }
        items[next].focus();
        e.preventDefault();
      }
    });
  })();

  /* ------------------------------------------------------------------ */
  /*  Full search page mode                                              */
  /* ------------------------------------------------------------------ */

  (function initSearchPage() {
    var pageInput = document.getElementById('eip-search-page-input');
    var pageResults = document.getElementById('eip-search-page-results');
    var pagePagination = document.getElementById('eip-search-page-pagination');
    var pageFilters = document.getElementById('eip-search-page-filters');
    if (!pageInput || !pageResults) return;

    var PER_PAGE = 25;
    var currentPage = 1;
    var lastData = null;
    var statusFilter = '';  // '' means no filter
    var typeFilter = '';    // '' means no filter; values: Core, Networking, Interface, ERC, Meta, Informational
    var authorFilter = '';  // '' means no filter; free-text author name search
    var ALL_STATUSES = ['Living', 'Final', 'Last Call', 'Review', 'Draft', 'Stagnant', 'Withdrawn'];
    var ALL_TYPES = ['Core', 'Networking', 'Interface', 'ERC', 'Meta', 'Informational'];

    // Returns true if a document matches the current typeFilter
    function docMatchesType(doc) {
      if (!typeFilter) return true;
      if (doc.type === typeFilter) return true;
      if (doc.category === typeFilter) return true;
      return false;
    }

    loadIndex();

    // Re-run search when index finishes loading (handles race condition)
    var indexCheckInterval = setInterval(function() {
      if (searchIndex.length > 0 || indexLoadFailed) {
        clearInterval(indexCheckInterval);
        if (searchIndex.length > 0) {
          var q = pageInput.value.trim();
          if (q.length >= 2) {
            doSearchAndRender();
          }
        }
      }
    }, 100);

    function getParam(name) {
      var match = window.location.search.match(new RegExp('[?&]' + name + '=([^&]*)'));
      return match ? decodeURIComponent(match[1].replace(/\+/g, ' ')) : '';
    }

    function buildFilterBar() {
      if (!pageFilters) return;
      var html = '';

      // ---- Status filter row ----
      html += '<div class="eip-search-page__filters">' +
        '<span class="eip-search-page__filter-label">Status:</span>' +
        '<button class="eip-search-page__filter-chip' + (!statusFilter ? ' eip-search-page__filter-chip--active' : '') + '" data-filter="status" data-value="">All</button>';
      for (var s = 0; s < ALL_STATUSES.length; s++) {
        var st = ALL_STATUSES[s];
        html += '<button class="eip-search-page__filter-chip' + (statusFilter === st ? ' eip-search-page__filter-chip--active' : '') + '" data-filter="status" data-value="' + st + '">' + st + '</button>';
      }
      html += '</div>';

      // ---- Type/Category filter row ----
      html += '<div class="eip-search-page__filters eip-search-page__filters--type">' +
        '<span class="eip-search-page__filter-label">Type:</span>' +
        '<button class="eip-search-page__filter-chip' + (!typeFilter ? ' eip-search-page__filter-chip--active' : '') + '" data-filter="type" data-value="">All</button>';
      for (var t = 0; t < ALL_TYPES.length; t++) {
        var tp = ALL_TYPES[t];
        html += '<button class="eip-search-page__filter-chip' + (typeFilter === tp ? ' eip-search-page__filter-chip--active' : '') + '" data-filter="type" data-value="' + tp + '">' + tp + '</button>';
      }
      html += '</div>';

      // ---- Author filter row ----
      html += '<div class="eip-search-page__filters eip-search-page__filters--author">' +
        '<span class="eip-search-page__filter-label">Author:</span>' +
        '<input type="text" id="eip-search-page-author-input" class="eip-search-page__author-input" placeholder="Filter by author name…" value="' + escapeHtml(authorFilter) + '" autocomplete="off" />' +
        (authorFilter ? '<button class="eip-search-page__filter-chip eip-search-page__filter-chip--clear" data-clear="author">✕ Clear</button>' : '') +
      '</div>';

      // ---- Clear-all button (only when any filter is active) ----
      if (statusFilter || typeFilter || authorFilter) {
        html += '<div class="eip-search-page__filters eip-search-page__filters--clear-all">' +
          '<button id="eip-search-page-clear-all" class="eip-search-page__filter-chip eip-search-page__filter-chip--clear-all">✕ Clear all filters</button>' +
        '</div>';
      }

      pageFilters.innerHTML = html;

      // Bind clear-all handler
      var clearAllBtn = document.getElementById('eip-search-page-clear-all');
      if (clearAllBtn) {
        clearAllBtn.addEventListener('click', function () {
          statusFilter = '';
          typeFilter = '';
          authorFilter = '';
          var authorInput = document.getElementById('eip-search-page-author-input');
          if (authorInput) authorInput.value = '';
          currentPage = 1;
          doSearchAndRender();
          updateUrl();
          buildFilterBar();
        });
      }

      // Bind click handlers for status + type chips
      pageFilters.querySelectorAll('.eip-search-page__filter-chip').forEach(function (btn) {
        if (btn.getAttribute('data-clear')) {
          btn.addEventListener('click', function () {
            authorFilter = '';
            document.getElementById('eip-search-page-author-input').value = '';
            currentPage = 1;
            doSearchAndRender();
            updateUrl();
            buildFilterBar();
          });
          return;
        }
        btn.addEventListener('click', function () {
          var filter = this.getAttribute('data-filter');
          var value = this.getAttribute('data-value');
          if (filter === 'status') {
            if (value === statusFilter) return;
            statusFilter = value;
          } else if (filter === 'type') {
            if (value === typeFilter) return;
            typeFilter = value;
          }
          currentPage = 1;
          doSearchAndRender();
          updateUrl();
          buildFilterBar();
        });
      });
    }

    function doSearchAndRender() {
      var raw = search(pageInput.value);
      var hasResults = raw && Array.isArray(raw.results);
      if (hasResults) {
        var filtered = [];
        for (var i = 0; i < raw.results.length; i++) {
          var doc = raw.results[i].doc;
          var keep = true;
          if (statusFilter && doc.status !== statusFilter) keep = false;
          if (typeFilter && !docMatchesType(doc)) keep = false;
          if (authorFilter) {
            var authorStr = (doc.author || '').toLowerCase();
            if (authorStr.indexOf(authorFilter.toLowerCase()) === -1) keep = false;
          }
          if (keep) filtered.push(raw.results[i]);
        }
        lastData = {
          results: filtered,
          tokens: raw.tokens,
          query: raw.query
        };
      } else {
        lastData = raw; // might be [] while index loads
      }
      renderPage(lastData, currentPage);
    }

    function updateUrl() {
      var q = pageInput.value.trim();
      var params = [];
      if (q.length >= 2) params.push('q=' + encodeURIComponent(q));
      if (statusFilter) params.push('status=' + encodeURIComponent(statusFilter));
      if (typeFilter) params.push('type=' + encodeURIComponent(typeFilter));
      if (authorFilter) params.push('author=' + encodeURIComponent(authorFilter));
      var url = baseurl + '/search/' + (params.length ? '?' + params.join('&') : '');
      window.history.replaceState(null, '', url);
    }

    function renderPage(data, page) {
      if (!data || !data.results || data.results.length === 0) {
        var parts = [];
        if (data && data.query) parts.push('matching &quot;' + escapeHtml(data.query) + '&quot;');
        if (statusFilter) parts.push('status: &quot;' + escapeHtml(statusFilter) + '&quot;');
        if (typeFilter) parts.push('type: &quot;' + escapeHtml(typeFilter) + '&quot;');
        if (authorFilter) parts.push('author: &quot;' + escapeHtml(authorFilter) + '&quot;');
        var emptyMsg = 'No EIPs found' + (parts.length ? ' with ' + parts.join(', ') : '') + '.';
        pageResults.innerHTML = '<div class="eip-search__empty">' + emptyMsg + '</div>';
        if (pagePagination) pagePagination.innerHTML = '';
        return;
      }

      var total = data.results.length;
      var totalPages = Math.ceil(total / PER_PAGE);
      var start = (page - 1) * PER_PAGE;
      var end = Math.min(start + PER_PAGE, total);

      // Results header
      var headerHtml = '<div class="eip-search-page__header">' +
        '<span class="eip-search-page__count">' + total + ' result' + (total !== 1 ? 's' : '') + ' for <strong>' + escapeHtml(data.query) + '</strong></span>' +
        '<span class="eip-search-page__range">Showing ' + (start + 1) + '–' + end + '</span>' +
      '</div>';

      // Result cards
      var listHtml = '';
      for (var i = start; i < end; i++) {
        listHtml += resultHtml(data.results[i].doc, data.tokens);
      }

      pageResults.innerHTML = headerHtml + listHtml;

      // Pagination controls
      if (pagePagination) {
        if (totalPages <= 1) { pagePagination.innerHTML = ''; return; }

        var p = '';
        p += '<div class="eip-search-page__pagination">';

        if (page > 1) {
          p += '<button class="eip-search-page__page-btn" data-page="' + (page - 1) + '">← Prev</button>';
        } else {
          p += '<span class="eip-search-page__page-btn eip-search-page__page-btn--disabled">← Prev</span>';
        }

        var windowStart = Math.max(1, page - 2);
        var windowEnd = Math.min(totalPages, page + 2);
        if (windowStart > 1) { p += '<span class="eip-search-page__page-dots">…</span>'; }
        for (var pn = windowStart; pn <= windowEnd; pn++) {
          p += '<button class="eip-search-page__page-btn' + (pn === page ? ' eip-search-page__page-btn--active' : '') + '" data-page="' + pn + '">' + pn + '</button>';
        }
        if (windowEnd < totalPages) { p += '<span class="eip-search-page__page-dots">…</span>'; }

        if (page < totalPages) {
          p += '<button class="eip-search-page__page-btn" data-page="' + (page + 1) + '">Next →</button>';
        } else {
          p += '<span class="eip-search-page__page-btn eip-search-page__page-btn--disabled">Next →</span>';
        }

        p += '</div>';
        pagePagination.innerHTML = p;

        pagePagination.querySelectorAll('[data-page]').forEach(function (btn) {
          btn.addEventListener('click', function () {
            var p = parseInt(this.getAttribute('data-page'), 10);
            if (p && p !== currentPage) {
              currentPage = p;
              renderPage(lastData, currentPage);
              window.scrollTo({ top: pageResults.offsetTop - 20, behavior: 'smooth' });
            }
          });
        });
      }
    }

    // Initial load from URL
    var initialQuery = getParam('q');
    var initialStatus = getParam('status');
    if (initialStatus && ALL_STATUSES.indexOf(initialStatus) !== -1) {
      statusFilter = initialStatus;
    }
    var initialType = getParam('type');
    if (initialType && ALL_TYPES.indexOf(initialType) !== -1) {
      typeFilter = initialType;
    }
    var initialAuthor = getParam('author');
    if (initialAuthor) {
      authorFilter = initialAuthor;
    }

    buildFilterBar();

    if (initialQuery) {
      pageInput.value = initialQuery;
      doSearchAndRender();
    }

    // Live search on input
    pageInput.addEventListener('input', debounce(function () {
      currentPage = 1;
      doSearchAndRender();
      updateUrl();
    }, 250));

    pageInput.addEventListener('keydown', function (e) {
      if (e.key === 'Enter') {
        updateUrl();
      }
    });

    // Author input live search
    function onAuthorInput() {
      var authorInput = document.getElementById('eip-search-page-author-input');
      if (!authorInput) return;
      authorFilter = authorInput.value.trim();
      currentPage = 1;
      doSearchAndRender();
      updateUrl();
      buildFilterBar();
    }

    // Use a delegated listener since the author input is rebuilt by buildFilterBar
    pageFilters.addEventListener('input', function (e) {
      if (e.target && e.target.id === 'eip-search-page-author-input') {
        onAuthorInput();
      }
    });
  })();
})();
