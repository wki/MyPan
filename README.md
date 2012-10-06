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

    add <module-spec> <repo/ver> [/<author>]
    
    delete <repo/ver>
    delete <repo/ver> / <module-spec>
    
    get <repo/ver> / <module-spec>
    
    list                # get all repositories
    list <repo>         # list versions
    list <repo/ver>     # list modules
    list <repo/ver>/<author>
    
    log <repo/ver>
    
    revert <repo/ver> <revision>


Config file (~/.mypan) -- win.ini Format

    [General]
    username = wolfgang
    password = secret
    server = mypan.mycompany.com


as a backend, a simple Plack based http-server is serving requests of
clients using it as a CPAN replacement and administrators modifying
repositories.


    typical URL layout:
      /repo
      /repo/ver
      /repo/ver/author
      /repo/ver/author/dist.tar.gz
    
    POST /repo/ver                --> create repository
    POST /repo/ver/author/dist    --> upload new dist
    
    GET /                         --> list repositories
    GET /repo                     --> list versions
    GET /repo/ver                 --> list modules
    GET /repo/ver/author          --> list modules of this author
    
    DELETE /repo/ver              --> delete repository
    DELETE /repo/ver/author/dist  --> delete dist
    DELETE /repo/ver/42           --> rollback to revision 42
    DELETE /repo/ver/-1           --> undo last step
    