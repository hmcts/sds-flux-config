              #!/usr/bin/env bash
              testkube get test curl-test --no-execution
              echo $?
              testkube get test netbox  --no-execution
              echo $?
              if [[ $(testkube get test curl-test --no-execution) ]]; then
              echo "----"
               testkube delete test curl-test
              fi

