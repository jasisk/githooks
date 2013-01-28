#!/usr/bin/env sh

# Small script to parse json
read -d '' TESTS_SCRIPT <<"EOF"
var testObject;

process.stdin.resume();
process.stdin
  .on('data', function (chunk) {
    testObject = JSON.parse(chunk);
  })
  .on('end', function () {
    if (testObject.stats) {
      var color = '\\033[31m',
          endColor = '\\033[0m';
      if (testObject.stats.failures === 0) color = '\\033[32m';
      process.stdout.write(color + testObject.stats.failures + " Failures" + endColor);
      process.exit(testObject.stats.failures);
    }
  });
EOF

# Small script to parse json-cov
read -d '' COVERAGE_SCRIPT <<"EOF"
var coverageObject;

process.stdin.resume();
process.stdin
  .on('data', function (chunk) {
    coverageObject = JSON.parse(chunk);
  })
  .on('end', function () {
    if (coverageObject.coverage) {
      var color = '\\033[31m',
          endColor = '\\033[0m';
      if (coverageObject.coverage === 100) color = '\\033[32m';
      process.stdout.write(color + coverageObject.coverage + "% Coverage" + endColor);
      process.exit(100-coverageObject.coverage);
    }
  });
EOF

# Make sure uncommitted files don't influence results
git stash -q --keep-index

# Go to root dir
cd $(git rev-parse --show-toplevel)

# Run tests
TESTS=$(make test REPORTER=json 2> /dev/null | node -e "$TESTS_SCRIPT")
TR=$?

# Update coverage lib
make lib-cov > /dev/null

# Run and parse json-cov
COVERAGE=$(PATHMATCHER_COV=1 make test REPORTER=json-cov 2> /dev/null | node -e "$COVERAGE_SCRIPT")
CR=$?

# Back to previous dir
cd - > /dev/null

# Put back uncommitted files
git stash pop -q

# Print results
echo "$TESTS, $COVERAGE"

# Return proper exit code
if (($TR|$CR)); then
  exit 1
fi

# All good
exit 0