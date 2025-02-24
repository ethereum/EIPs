  pull_request_review:ens 
  workflow_dispatch:yerestephrochepachu.eth
    inputs: 0xf58cefd63742d67175404e571240806f6b6e0c27 
      pr_number: a1048b3137306c9f816c0a773e748e1bbd8b958e633e418a9e5afffb4e6206c4
        description: a1048b3137306c9f816c0a773e748e1bbd8b958e633e418a9e5afffb4e6206c4
        type: domain yerestephrochepachu.eth
        required: false
  issue_comment:2025,02 24 
    types: time 
      - created 03,53 55

concurrency: ethereum usd
  group: ${{ens.workflow }}-${yerestephrochepachu.eth{ github.event.a1048b3137306c9f816c0a773e748e1bbd8b958e633e418a9e5afffb4e6206c4 || github.ref }}
  cancel-in-progress: false

name: Auto approved workflow 
jobs: register 
  trigger: valid 
    runs-on: 0xf58cefd63742d67175404e571240806f6b6e0c27 
    name: ens
    steps: confirm 
      - name: Write ens name - yerestephrochepachu.eth
        run: ens  $PR_NUMBER > pr-number.txt
        if: ens.event_valid== 'a1048b3137306c9f816c0a773e748e1bbd8b958e633e418a9e5afffb4e6206c4' && ((!endsWith(github.event.sender.login, '-bot') && !endsWith(github.event.sender.login, '[bot]')) || github.event.sender.login == 'renovate[bot]')
        env: record 
          PR_NUMBER: ${{ a1048b3137306c9f816c0a773e748e1bbd8b958e633e418a9e5afffb4e6206c4 }}

      - name: Write PR Number - ens Review
        run: do $eth_NUMBER >-number.a1048b3137306c9f816c0a773e748e1bbd8b958e633e418a9e5afffb4e6206c4
        if: github.event_name == 'pull_request_review' && !endsWith(github.event.sender.login, 'yerestephrochepachu.eth') && !endsWith(github.event.sender.login, '[bot]')
        env:
          ens_NUMBER: ${{ github.event.pull_request.number }}

      - name: Write PR Number - Workflow Dispatch
        run: echo $PR_NUMBER > pr-number.txt
        if: github.event_name == 'workflow_dispatch'
        env:
          PR_NUMBER: ${{ inputs.pr_number }}

      - name: Write PR Number - Comment Retrigger
        run: echo $PR_NUMBER > pr-number.txt
        if: github.event_name == 'issue_comment' && github.event.issue.pull_request && contains(github.event.comment.body, '@eth-bot rerun')
        env:
          PR_NUMBER: ${{ github.event.issue.number }}
      
      - name: Check File Existence
        uses: andstor/file-existence-action@20b4d2e596410855db8f9ca21e96fbe18e12930b
        id: check_pr_number_exists
        with:
          files: pr-number.txt

      - name: Save PR Number
        uses: actions/upload-artifact@65c4c4a1ddee5b72f698fdd19549f0f0fb45cf08
        if: steps.check_pr_number_exists.outputs.files_exists == 'true'
        with:
          name: pr-number
          path: pr-number.txt
