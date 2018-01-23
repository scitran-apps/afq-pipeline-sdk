# Create Docker container that can run afq analysis.

# Start with the Matlab r2013b runtime container
FROM scitran/afq-pipeline:v1.0.1
MAINTAINER Michael Perry <lmperry@stanford.edu>

############################
# ENV

ENV FLYWHEEL /flywheel/v0


############################
# FUZZY

RUN apt-get update && apt-get install -y \
    python-pip \
    git \
    python-levenshtein

RUN pip install --upgrade pip && \
    pip install fuzzywuzzy && \
    pip install fuzzywuzzy[speedup]


############################
# Install the Flywheel SDK

WORKDIR /opt/flywheel
# Commit for version of SDK to build
ENV COMMIT af59edf
ENV LD_LIBRARY_PATH_TMP ${LD_LIBRARY_PATH}
ENV LD_LIBRARY_PATH ' '
RUN git clone https://github.com/flywheel-io/sdk workspace/src/flywheel.io/sdk
RUN ln -s workspace/src/flywheel.io/sdk sdk
RUN cd sdk && git checkout $COMMIT >> /dev/null && cd ../
RUN sdk/make.sh
RUN sdk/bridge/make.sh
ENV PYTHONPATH /opt/flywheel/workspace/src/flywheel.io/sdk/bridge/dist/python/flywheel
ENV LD_LIBRARY_PATH ${LD_LIBRARY_PATH_TMP}


############################
# FLYWHEEL

COPY fw_sdk_functions.py ${FLYWHEEL}/
COPY fw_sdk_getData.py ${FLYWHEEL}/
COPY run ${FLYWHEEL}/run
COPY manifest.json ${FLYWHEEL}/manifest.json


############################
# ENV preservation

RUN env -u HOSTNAME -u PWD | \
  awk -F = '{ print "export " $1 "=\"" $2 "\"" }' > ${FLYWHEEL}/docker-env.sh


############################
# Configure entrypoint
RUN chmod +x ${FLYWHEEL}/*
ENTRYPOINT ["/flywheel/v0/run"]
