FROM quay.io/official-images/debian

RUN apt-get update && apt-get install curl debootstrap gpg make binutils unzip
RUN apt-get install wget apt-transport-https gnupg lsb-release &&
	&& wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | apt-key add -
	&& echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | tee -a /etc/apt/sources.list.d/trivy.list
	&& apt-get update
	&& apt-get install trivy