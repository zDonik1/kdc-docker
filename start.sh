#!/usr/bin/env sh

echo "==================================================================================="
echo "==== Kerberos KDC and Kadmin ======================================================"
echo "==================================================================================="
KADMIN_PRINCIPAL_FULL=$KADMIN_PRINCIPAL@$REALM

echo "REALM: $REALM"
echo "KADMIN_PRINCIPAL_FULL: $KADMIN_PRINCIPAL_FULL"
echo ""

echo "==================================================================================="
echo "==== /etc/krb5.conf ==============================================================="
echo "==================================================================================="
tee /etc/krb5.conf <<EOF
[libdefaults]
    default_realm = $REALM
    spake_preauth_groups = edwards25519

[realms]
    $REALM = {
        kdc_ports = 88,750
        kadmind_port = 749
        kdc = $KDC_KADMIN_SERVER
        admin_server = $KDC_KADMIN_SERVER
    }
EOF
echo ""

echo "==================================================================================="
echo "==== /etc/krb5kdc/kdc.conf ========================================================"
echo "==================================================================================="
tee /var/lib/krb5kdc/kdc.conf <<EOF
[realms]
    $REALM = {
        max_life = 10h 0m 0s
        max_renewable_life = 7d 0h 0m 0s
        default_principal_flags = +preauth
    }
EOF
echo ""

echo "==================================================================================="
echo "==== /etc/krb5kdc/kadm5.acl ======================================================="
echo "==================================================================================="
tee /var/lib/krb5kdc/kadm5.acl <<EOF
*/admin@MUKHTAROV.NET *
EOF
echo ""

echo "==================================================================================="
echo "==== Creating realm ==============================================================="
echo "==================================================================================="
MASTER_PASSWORD=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w30 | head -n1)
kdb5_util create -r $REALM -s <<EOF
$MASTER_PASSWORD
$MASTER_PASSWORD
EOF
echo ""

echo "==================================================================================="
echo "==== Create the principals in the acl ============================================="
echo "==================================================================================="
echo "Adding $KADMIN_PRINCIPAL principal"
kadmin.local -q "delete_principal -force $KADMIN_PRINCIPAL_FULL"
echo ""
kadmin.local -q "addprinc -pw $KADMIN_PASSWORD $KADMIN_PRINCIPAL_FULL"
echo ""

echo "==================================================================================="
echo "==== Run the services ============================================================="
echo "==================================================================================="

krb5kdc
kadmind -nofork || true
sleep infinity
