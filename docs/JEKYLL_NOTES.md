# Jekyll Configuration Notes

## Requirements

- Ruby 3.1.4 exactly (later versions not supported)
- Bundler gem
- All dependencies from Gemfile

## Setup

1. Install Ruby 3.1.4:
   ```sh
   ruby --version  # Should show 3.1.4
   ```

2. Install Bundler:
   ```sh
   gem install bundler
   ```

3. Install dependencies:
   ```sh
   bundle install
   ```

## Running Jekyll

Build and serve the site:
```sh
bundle exec jekyll serve
```

The site will be available at `http://localhost:4000`

## Troubleshooting

### Ruby Version Issues

If you see `undefined method 'exists' for File:Class`:
- This means you're using a Ruby version other than 3.1.4
- Use rbenv or rvm to install exactly 3.1.4

### Dependency Issues

If `bundle install` fails:
- Clear bundler cache: `bundle clean --force`
- Reinstall: `bundle install`

### Build Failures

If Jekyll build fails:
- Clear Jekyll cache: `bundle exec jekyll clean`
- Check Ruby version: `ruby --version`
- Reinstall dependencies: `bundle install`

