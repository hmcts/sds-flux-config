PR=$(gh pr list --author app/renovate --search "Update Helm release - netbox" --state open --repo hmcts/sds-flux-config --json number,url)

NUMBER=$(echo $PR | jq '.[].number')

URL=$(echo $PR | jq '.[].url')

MERGE_COMMIT=$(gh pr view $URL --json mergeCommit -q .mergeCommit.oid)

git checkout -b revert-commit-$NUMBER

git revert -m 1 $mergeCommit --no-edit

git add .

git commit -m "Reverting pull request #$NUMBER"

gh pr create -t "Revert PR#$NUMBER"