MyPan
=====

manage collections of Perl modules which act like CPAN

the frontend is a simple commandline tool

    mypan [options] command [arguments]

    -h          help
    -v          be verbose
    -n          dryrun
    -s host     specify a server (if different from config)
    -c file     specify a different config file

    create <repo/ver>
    
    add <module-spec> <repo/ver> [/<author>]
    
    delete <repo/ver>
    delete <repo/ver> / <module-spec>
    
    list                # get all repositories
    list <repo>         # list versions
    list <repo/ver>     # list modules
    list <repo/ver>/<author>
    
    log <repo/ver>
    
    revisions <repo/ver>
    
    revert <repo/ver> <revision>


Config file (~/.mypan) -- YAML Format

    username: wolfgang
    password: secret
    server: mypan.mycompany.com
