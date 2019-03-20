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
# Install the Flywheel SDK

RUN pip install flywheel-sdk


############################
# FUZZY

RUN pip install --upgrade pip && \
    pip install fuzzywuzzy && \
    pip install fuzzywuzzy[speedup]


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
