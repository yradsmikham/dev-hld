# Unit Testing
A unit test framework for shell scripts that relies on [shUnit2](https://github.com/kward/shunit2). The unit test will perform checks to ensure various components of `build_pat.sh` runs as expected. 

## Prerequisites

This unit test makes the following assumptions:

- The user has an existing AKS Manifest repository (e.g. [yradsmikham/walmart-k8s](https://github.com/yradsmikham/walmart-k8s))
- A Personal Access Token is generated that grants permission to read/write to the AKS Manifest repo.

## Instructions

1. Clone the repository.
2. Provide values to environment variables in `environment.properties`.
3. In terrminal, navigate to  `../unit_test/tests` directory and run `./unit_test.sh`
