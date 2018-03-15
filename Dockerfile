# Create Docker container that can run afq analysis with the Flywheel SDK.

# Start with the afq-pipeline container
FROM scitran/afq-pipeline:1.0.2
MAINTAINER Michael Perry <lmperry@stanford.edu>

ENV FLYWHEEL /flywheel/v0
WORKDIR ${FLYWHEEL}
COPY run ${FLYWHEEL}/run

###########################
# Install dependencies

RUN apt-get update && apt-get install -y --force-yes \
    python-pip \
    git \
    python-levenshtein


############################
# FUZZY

RUN pip install --upgrade pip && \
    pip install fuzzywuzzy && \
    pip install fuzzywuzzy[speedup]


############################
# Install the Flywheel SDK

WORKDIR /opt/flywheel
# Commit for version of SDK to build
ENV COMMIT bf2e0d6
ENV LD_LIBRARY_PATH_TMP ${LD_LIBRARY_PATH}
ENV LD_LIBRARY_PATH ' '
RUN git clone https://github.com/flywheel-io/sdk workspace/src/flywheel.io/sdk
RUN ln -s workspace/src/flywheel.io/sdk sdk
RUN cd sdk && git checkout $COMMIT && cd ../
RUN sdk/make.sh
RUN sdk/bridge/make.sh
ENV PYTHONPATH /opt/flywheel/workspace/src/flywheel.io/sdk/bridge/dist/python/flywheel
ENV LD_LIBRARY_PATH ${LD_LIBRARY_PATH_TMP}


############################
# FLYWHEEL

COPY fw_sdk_functions.py ${FLYWHEEL}/
COPY fw_sdk_getData.py ${FLYWHEEL}/


############################
# ENV preservation for Flywheel Engine

RUN env -u HOSTNAME -u PWD | \
  awk -F = '{ print "export " $1 "=\"" $2 "\"" }' > ${FLYWHEEL}/docker-env.sh

# Configure entrypoint
RUN chmod +x ${FLYWHEEL}/*
ENTRYPOINT ["/flywheel/v0/run"]
COPY manifest.json ${FLYWHEEL}/manifest.json
