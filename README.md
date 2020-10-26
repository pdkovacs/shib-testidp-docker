Helps automatically set up a shibboleth-based SAML IdP (backed by an LDAP server) for basic integration testing solely &ndash; carefully avoiding any security where possible :-).

It was initially meant to be in a docker-image, but it is already helpful as it is. (I haven't given up on the idea of dockering it, because a docker image would be a little easier to build.)

#### Customization points:

1. `ldap.properties`

    The properties in the section headed by the `These call for customization the loudest:` comment.

1. `build.sh`
    * The `metadataFile` file location attribute for the SP metadata
    * Environment-specific valus for `$jetty/start.ini`:
        * `java.io.tmpdir` and
        * `idp.home` 

1. `shibb-idp-install.properties`
    
    The properties in the section headed by the `Customize these:` comment.
