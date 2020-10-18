#!/bin/bash

jetty=jetty-distribution-9.4.32.v20200930
if [ ! -f $jetty.zip ];
then
    curl https://repo1.maven.org/maven2/org/eclipse/jetty/jetty-distribution/9.4.32.v20200930/$jetty.zip -o $jetty.zip
    sha1sum -c $jetty.zip.sha1 || exit 1
    unzip $jetty.zip
fi

shibidp=shibboleth-identity-provider-3.4.7
if [ ! -f $shibidp.zip ];
then
    curl https://shibboleth.net/downloads/identity-provider/latest3/$shibidp.zip -o $shibidp.zip
    sha256sum -c $shibidp.zip.sha256 || exit 1
    unzip $shibidp.zip
fi

###############################################################################
# $shibidp/conf/attribute-filter.xml
###############################################################################
attrfilter_conf=$shibidp/conf/attribute-filter.xml
filter_pcygr_closing_tag='</AttributeFilterPolicyGroup>'
grep -v "$filter_pcygr_closing_tag" $attrfilter_conf > tmp && mv tmp $attrfilter_conf
cat >> $attrfilter_conf <<EOF
    <AttributeFilterPolicy id="allow-mail">
        <PolicyRequirementRule xsi:type="ANY" />

        <AttributeRule attributeID="uid" permitAny="true" />
        <AttributeRule attributeID="mail" permitAny="true" />
    </AttributeFilterPolicy>
EOF
echo $filter_pcygr_closing_tag >> $attrfilter_conf

###############################################################################
# $shibidp/conf/saml-nameid.xml
###############################################################################
nameid_config=$shibidp/conf/saml-nameid.xml
sed -i '41d;46d' $nameid_config

###############################################################################
# $shibidp/conf/ldap.properties
###############################################################################
cp ldap.properties $shibidp/conf/ldap.properties

###############################################################################
# $shibidp/conf/idp.properties
###############################################################################
cat >> $shibidp/conf/idp.properties <<EOF

idp.encryption.optional = true
idp.sealer.storePassword=kalap
idp.sealer.keyPassword=kalap
EOF

###############################################################################
# $shibidp/conf/metadata-providers.xml
###############################################################################
# TODO: Do this in entrypoint
provider_meta=$shibidp/conf/metadata-providers.xml
provmeta_closing_tag='</MetadataProvider>'
grep -v "$provmeta_closing_tag" $provider_meta > tmp && mv tmp $provider_meta
cat >> $provider_meta <<EOF
    <MetadataProvider id="sp-metadata"
                  xsi:type="FilesystemMetadataProvider"
                  metadataFile="C:/Users/pkovacs/chemaxon/git/pkovacs/ml-work/data/config/saml/sp-provider.xml"/>
EOF
echo $provmeta_closing_tag >> $provider_meta

###############################################################################
# web.xml
###############################################################################
sed -i -e 's|<secure>true</secure>|<secure>false</secure>|' $shibidp/webapp/WEB-INF/web.xml

###############################################################################
# WAR
###############################################################################
cd $shibidp/bin
cmd.exe //C install.bat -propertyfile ..\\..\\shibb-idp-install.properties
cd -
cp idp/war/idp.war $jetty/webapps/

###############################################################################
# $jetty/start.ini
###############################################################################
cat >> $jetty/start.ini <<EOF
--exec
-XX:+UseG1GC
-Xmx1500m
-Djava.security.egd=file:/dev/urandom
-Djava.io.tmpdir=C:/Users/pkovacs/tmp
-Didp.home=C:/Users/pkovacs/github/pdkovacs/shib-testidp-docker/idp
EOF
