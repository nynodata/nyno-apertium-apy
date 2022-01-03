FROM apertium/base
LABEL maintainer sushain@skc.name
WORKDIR /root

ARG site=

# Install packaged dependencies

# RUN apt-get -qq update && apt-get -qq install \
RUN apt-get --allow-releaseinfo-change update && apt-get -y install \
    apt-utils \
    automake \
    gcc-multilib \
    git \
    wget \
    curl \
	lexd \
    python \
    python3-dev \
    python3-pip \
    sqlite3 \
    zlib1g-dev

# Install CLD2

RUN git clone https://github.com/CLD2Owners/cld2
RUN cd /root/cld2/internal && \
    CPPFLAGS='-std=c++98' ./compile_libs.sh && \
    cp *.so /usr/lib/
RUN git clone https://github.com/mikemccand/chromium-compact-language-detector
RUN cd /root/chromium-compact-language-detector && \
    python3 setup.py build && python3 setup_full.py build && \
    python3 setup.py install && python3 setup_full.py install

# Install Apertium-related libraries (and a test pair)
RUN apt-get -qq update && apt-get -y install giella-core giella-shared hfst-ospell
# Removed getting last versions because of 'passiv' error
RUN apt-get -qq update && apt-get -y install apertium-nno-nob
RUN apt-get -qq update && apt-get -y install apertium-nob
RUN apt-get -qq update && apt-get -y install apertium-nno

# THIS update to newest cg3 & llibtools versions
# Is a bit dangerous bc. translation tagging not used by many and has changed over time.
# Last working version is CG-3 Disambiguator release version 1.3.2.13891
RUN curl -sS https://apertium.projectjj.com/apt/install-release.sh | bash
RUN apt-get -y --allow-downgrades install  apertium-all-dev

# Install APy
COPY Pipfile apertium-apy/
COPY Pipfile.lock apertium-apy/
RUN pip3 install pipenv
RUN cd apertium-apy && pipenv install --deploy --system

COPY . apertium-apy
RUN cd apertium-apy && make -j2

# patch nynonls nls
# patch nynonls nls
COPY nls/nls_plugin /usr/bin/
COPY nls/apertium /usr/bin/
COPY nls/nob_t-nno.mode /usr/share/apertium/modes/modes/nob_t-nno.mode
COPY nls/nob_h-nno.mode /usr/share/apertium/modes/modes/nob_h-nno.mode
COPY nls/nob_d-nno.mode /usr/share/apertium/modes/modes/nob_d-nno.mode
COPY nls/apertium-nno/ /usr/share/apertium/apertium-nno/
COPY nls/apertium-nob/ /usr/share/apertium/apertium-nob/
COPY nls/apertium-nno-nob/ /usr/share/apertium/apertium-nno-nob/
RUN chmod 755 /usr/bin/apertium
RUN chmod 755 /usr/bin/nls_plugin


EXPOSE 2737
# ENTRYPOINT ["python3", "/root/apertium-apy/servlet.py", "--lang-names", "/root/apertium-apy/langNames.db"]
CMD ["/usr/share/apertium/modes", "--port", "2737"]
