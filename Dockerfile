# ARG IMAGE=intersystemsdc/irishealth-community:2023.2-zpm
ARG IMAGE=intersystemsdc/irishealth-community:latest

WORKDIR /home/irisowner/irisdev
#RUN chown ${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} /opt/irisapp

# run iris and initial 
RUN --mount=type=bind,src=.,dst=. \
    pip3 install jinja2 && \ 
    iris start IRIS && \
	iris session IRIS < iris.script && \
    iris stop IRIS quietly
