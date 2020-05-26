# [![Docker Repository on Quay](https://quay.io/repository/mocaccino/micro/status "Docker Repository on Quay")](https://quay.io/repository/mocaccino/micro) mocaccino-micro

## Architecture

Musl based distro. Targeting containers and servers. Not completely static, few of the packages are, depending on the scope and security support.

- [luet](https://github.com/mudler/luet) as a Package Manager and Building toolchain
- [s6](http://skarnet.org/software/s6/) as an init system

## To package yet:
- [s6/66](https://framagit.org/Obarun/66/-/tree/master)

## How to build all mocaccino-micro packages

### Prerequisites

- Docker/img
- luet installed (+container-diff) in `/usr/bin/luet` (arm build)
- make

See also the [luet official docs](https://luet-lab.github.io/docs/docs/getting-started/#setup)

    make build-all
    make create-repo

done! a `build/` folder will be created, ready to be used by Luet clients.

## How to build packages based on mocaccino-micro

There are three ways to build packages:
- Use luet and clone this tree. Specify as an additional tree where you store your specfiles, and point the `luet build` command to both trees (with multiple ```--tree```)
- Add a submodule to your spectree pointing to this repository
- Base your specfile from mocaccino-micro docker images.

See also [how to create a repository](https://luet-lab.github.io/docs/docs/overview/repositories/#example)