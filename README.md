Webapollo docker
===================

This docker image is part of the eBioKit 2017 project.

This docker image extends and distributes the following software:

#### WebApollo

- Based on [Apollo 2.X Docker Image](https://github.com/GMOD/docker-apollo).
- This docker image distributes the [Apollo project](https://github.com/GMOD/Apollo).
- [Licensed under special license](https://raw.githubusercontent.com/GMOD/Apollo/master/LICENSE.md).
- Citation
> Dunn NA, Munoz-Torres MC, Unni D, Yao E, Rasche E, Bretaudeau A, Holmes IH, Elsik CG; Lewis SE (2017). GMOD/Apollo: Apollo2.0.6(JB#29795a1bbb) Zenodo. [DOI:10.5281/zenodo.268535](https://doi.org/10.5281/zenodo.268535).

> Lee E, Helt GA, Reese JT, Munoz-Torres MC, Childers CP, Buels RM, Stein L, Holmes IH, Elsik CG, Lewis SE. 2013. Apollo: a web-based genomic annotation editing platform. [Genome Biol 14:R93](http://genomebiology.com/2013/14/8/R93/abstract).


## Running the Container

The container is publicly available as `ebiokit/docker-webapollo`. The recommended method for launching the container is via docker-compose due to a dependency on a postgres image.

## Quickstart

This procedure starts tomcat in a standard virtualised environment with a PostgreSQL database with [Chado](http://gmod.org/wiki/Introduction_to_Chado).

- Install [docker](https://docs.docker.com/engine/installation/) for your system if not previously done.
- `docker run -it -p 8888:8080 ebiokit/docker-webapollo`
- Apollo will be available at [http://localhost:8888/](http://localhost:8888/)

### Versions

The following versions are available for WebApollo docker:
- latest: the default branch for WebApollo docker. This version does not include the Apollo tools for preparing your data.
- tools: this version includes the Apollo tools for preparing your data.


### Logging In

The default credentials in this image are below. Credentials can be changed in the docker-compose file:

| Credentials |                    |
| ---         | ------------------ |
| Username    | `admin@local.host` |
| Password    | `password`         |

### About the eBioKit project

The eBioKit is a system running multiple open source web services on an Apple Mac-mini where all databases are stored locally.
This reduces the need for a fast internet connection while giving the users an opportunity to incorporate their data sets in widely used web services.

The eBioKit is developed by the SLU Global Bioinformatics Centre (SGBC), an academic research and educational initiative aimed to build a long-term successful bioinformatics infrastructure facility that serves the Swedish University for Agricultural Sciences (SLU) and life science research communities worldwide.

Find more information at [http://ebiokit.eu](http://ebiokit.eu)  and at the [SGBC](http://sgbc.slu.se/) website.

**Contact** [ebiokit@gmail.com](ebiokit@gmail.com)

<p style="text-align:center">
<img height=100 src="https://avatars0.githubusercontent.com/u/24695838?v=3&s=200">
</p>
