#!/bin/bash
#
# Adopted from https://github.com/tmcdonell/travis-scripts/blob/dfaac280ac2082cd6bcaba3217428347899f2975/update-accelerate-buildbot.sh

set -e

if [ "$BUILD_CUML" == "1" ]; then
  CUDA_REL=${CUDA:0:3}
  if [ "${CUDA:0:2}" == '10' ]; then
    # CUDA 10 release
    CUDA_REL=${CUDA:0:4}
  fi

  if [ "$BUILD_ABI" == "1" ]; then
    export UPLOADFILE=`conda build conda/recipes/cuml -c conda-forge -c numba -c rapidsai/label/cuda${CUDA_REL} -c nvidia/label/cuda${CUDA_REL} -c pytorch -c defaults --python=${PYTHON} --output`
  else
    export UPLOADFILE=`conda build conda/recipes/cuml -c conda-forge/label/cf201901 -c numba -c rapidsai/label/cf201901-cuda${CUDA_REL} -c nvidia/label/cf201901-cuda${CUDA_REL} -c pytorch -c defaults --python=${PYTHON} --output`
  fi

  SOURCE_BRANCH=master

  if [ "$LABEL_MAIN" == "1" -a "$BUILD_ABI" == "1" ]; then
    LABEL_OPTION="--label main --label cuda${CUDA_REL}"
  elif [ "$LABEL_MAIN" == "0" -a "$BUILD_ABI" == "1" ]; then
    LABEL_OPTION="--label dev --label cuda${CUDA_REL}"
  elif [ "$LABEL_MAIN" == "1" -a "$BUILD_ABI" == "0" ]; then
    LABEL_OPTION="--label cf201901 --label cf201901-cuda${CUDA_REL}"
  elif [ "$LABEL_MAIN" == "0" -a "$BUILD_ABI" == "0" ]; then
    LABEL_OPTION="--label cf201901-dev --label cf201901-cuda${CUDA_REL}"
  else
    echo "Unknown label configuration LABEL_MAIN='$LABEL_MAIN' BUILD_ABI='$BUILD_ABI'"
    exit 1
  fi
  echo "LABEL_OPTION=${LABEL_OPTION}"

  test -e ${UPLOADFILE}

  # Restrict uploads to master branch
  if [ ${GIT_BRANCH} != ${SOURCE_BRANCH} ]; then
    echo "Skipping upload"
    return 0
  fi

  if [ -z "$MY_UPLOAD_KEY" ]; then
    echo "No upload key"
    return 0
  fi

  echo "Upload"
  echo ${UPLOADFILE}
  anaconda -t ${MY_UPLOAD_KEY} upload -u rapidsai ${LABEL_OPTION} --force ${UPLOADFILE}
fi
