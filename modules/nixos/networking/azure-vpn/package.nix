# Microsoft Azure VPN Client package for NixOS
# Based on community work from:
# - https://discourse.nixos.org/t/run-microsoft-azurevpnclient-on-nixos/57066
# - https://discourse.nixos.org/t/help-getting-azure-vpn-to-work/60309
# - https://github.com/Elias-Graf/nix-azure-vpn
{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  openssl,
  gtk3,
  libsecret,
  cairo,
  nss,
  nspr,
  libuuid,
  at-spi2-core,
  libdrm,
  mesa,
  gtk2,
  glib,
  pango,
  atk,
  curl,
  zenity,
  cacert,
  openvpn,
  buildFHSEnv,
  writeShellScript,
  libcap,
}:
let
  pname = "microsoft-azurevpnclient";
  version = "3.0.0";

  # DigiCert Global Root G2 certificate (required by Azure VPN)
  # This is a well-known public root CA certificate
  digiCertGlobalRootG2 = ''
    -----BEGIN CERTIFICATE-----
    MIIDjjCCAnagAwIBAgIQAzrx5qcRqaC7KGSxHQn65TANBgkqhkiG9w0BAQsFADBh
    MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3
    d3cuZGlnaWNlcnQuY29tMSAwHgYDVQQDExdEaWdpQ2VydCBHbG9iYWwgUm9vdCBH
    MjAeFw0xMzA4MDExMjAwMDBaFw0zODAxMTUxMjAwMDBaMGExCzAJBgNVBAYTAlVT
    MRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5j
    b20xIDAeBgNVBAMTF0RpZ2lDZXJ0IEdsb2JhbCBSb290IEcyMIIBIjANBgkqhkiG
    9w0BAQEFAAOCAQ8AMIIBCgKCAQEAuzfNNNx7a8myaJCtSnX/RrohCgiN9RlUyfuI
    2/Ou8jqJkTx65qsGGmvPrC3oXgkkRLpimn7Wo6h+4FR1IAWsULecYxpsMNzaHxmx
    1x7e/dfgy5SDN67sH0NO3Xss0r0upS/kqbitOtSZpLYl6ZtrAGCSYP9PIUkY92eQ
    q2EGnI/yuum06ZIya7XzV+hdG82MHauVBJVJ8zUtluNJbd134/tJS7SsVQepj5Wz
    tCO7TG1F8PapspUwtP1MVYwnSlcUfIKdzXOS0xZKBgyMUNGPHgm+F6HmIcr9g+UQ
    vIOlCsRnKPZzFBQ9RnbDhxSJITRNrw9FDKZJobq7nMWxM4MphQIDAQABo0IwQDAP
    BgNVHRMBAf8EBTADAQH/MA4GA1UdDwEB/wQEAwIBhjAdBgNVHQ4EFgQUTiJUIBiV
    5uNu5g/6+rkS7QYXjzkwDQYJKoZIhvcNAQELBQADggEBAGBnKJRvDkhj6zHd6mcY
    1Yl9PMCcit6E7o1xAw7qDz/OGaXvtJCXPMW/QYNBJ/STqEhjY9v3u5p3gLBZTyFM
    uNhM1WrPyKwQGPpvqtdJPlkl0WOXW7wB7g5rQBpHMcKQ7DrFFMoXQqW1+w3A6qHu
    Kd3eNRjEqOxAQ/XPXwZnUoTl70l8zKdPF9VZy2RkE6+y2Cy6N5J2K6d5KaOh5uLo
    9T0kYG8b3A5Q0bU/ek7z7vGf6TySX4CnkPZ7qbHd4yzDICqNkm4r6dwbOkzJ3izT
    UDLMW5cpqCT1GHLQFlBzGMkpJ9QyPJfLMJDzCd2jvF7IIe6eOBMhveCJbyTnoyOJ
    3DY=
    -----END CERTIFICATE-----
  '';

  # Runtime libraries needed by the Azure VPN client
  runtimeLibs = [
    zenity
    openssl
    gtk3
    libsecret
    cairo
    nss
    nspr
    libuuid
    stdenv.cc.cc.lib
    at-spi2-core
    libdrm
    mesa
    gtk2
    glib
    pango
    atk
    curl
    cacert
    openvpn
  ];

  # DigiCert Global Root CA certificate (alternative, used by some Azure configurations)
  digiCertGlobalRootCA = ''
    -----BEGIN CERTIFICATE-----
    MIIDrzCCApegAwIBAgIQCDvgVpBCRrGhdWrJWZHHSjANBgkqhkiG9w0BAQUFADBh
    MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3
    d3cuZGlnaWNlcnQuY29tMSAwHgYDVQQDExdEaWdpQ2VydCBHbG9iYWwgUm9vdCBD
    QTAeFw0wNjExMTAwMDAwMDBaFw0zMTExMTAwMDAwMDBaMGExCzAJBgNVBAYTAlVT
    MRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5j
    b20xIDAeBgNVBAMTF0RpZ2lDZXJ0IEdsb2JhbCBSb290IENBMIIBIjANBgkqhkiG
    9w0BAQEFAAOCAQ8AMIIBCgKCAQEA4jvhEXLeqKTTo1eqUKKPC3eQyaKl7hLOllsB
    CSDMAZOnTjC3U/dDxGkAV53ijSLdhwZAAIEJzs4bg7/fzTtxRuLWZscFs3YnFo97
    nh6Vfe63SKMI2tavegw5BmV/Sl0fvBf4q77uKNd0f3p4mVmFaG5cIzJLv07A6Fpt
    43C/dxC//AH2hdmoRBBYMql1GNXRor5H4idq9Joz+EkIYIvUX7Q6hL+hqkpMfT7P
    T19sdl6gSzeRntwi5m3OFBqOasv+zbMUZBfHWymeMr/y7vrTC0LUq7dBMtoM1O/4
    gdW7jVg/tRvoSSiicNoxBN33shbyTApOB6jtSj1etX+jkMOvJwIDAQABo2MwYTAO
    BgNVHQ8BAf8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUA95QNVbR
    TLtm8KPiGxvDl7I90VUwHwYDVR0jBBgwFoAUA95QNVbRTLtm8KPiGxvDl7I90VUw
    DQYJKoZIhvcNAQEFBQADggEBAMucN6pIExIK+t1EnE9SsPTfrgT1eXkIoyQY/Esr
    hMAtudXH/vTBH1jLuG2cenTnmCmrEbXjcKChzUyImZOMkXDiqw8cvpOp/2PV5Adg
    06O/nVsJ8dWO41P0jmP6P6fbtGbfYmbW0W5BjfIttep3Sp+dWOIrWcBAI+0tKIJF
    PnlUkiaY4IBIqDfv8NZ5YBberOgOzW6sRBc4L0na4UU+Krk2U886UAb3LujEV0ls
    YSEY1QSteDwsOoBrp+uvFRTp2InBuThs4pFsiv9kuXclVzDAGySj4dzp30d8tbQk
    CAUw7C29C79Fv1C5qfPrmAESrciIxpg0X40KPMbp1ZWVbd4=
    -----END CERTIFICATE-----
  '';

  # The unpacked and patched Azure VPN client
  unpacked = stdenv.mkDerivation {
    inherit pname version;

    src = fetchurl {
      url = "https://packages.microsoft.com/ubuntu/22.04/prod/pool/main/m/microsoft-azurevpnclient/microsoft-azurevpnclient_${version}_amd64.deb";
      hash = "sha256-nl02BDPR03TZoQUbspplED6BynTr6qNRVdHw6fyUV3s=";
    };

    runtimeDependencies = [ zenity ];

    nativeBuildInputs = [
      dpkg
      autoPatchelfHook
      makeWrapper
      libcap
    ];

    buildInputs = runtimeLibs;

    unpackPhase = ''
      dpkg-deb -x $src .
    '';

    installPhase = ''
      mkdir -p $out
      cp -r opt $out
      cp -r usr/* $out

      mkdir -p $out/bin

      ln -s $out/opt/microsoft/microsoft-azurevpnclient/microsoft-azurevpnclient $out/bin/microsoft-azurevpnclient
      ln -s $out/opt/microsoft/microsoft-azurevpnclient/lib $out

      wrapProgram $out/bin/microsoft-azurevpnclient \
        --prefix SSL_CERT_DIR : "${cacert.unbundled}/etc/ssl/certs" \
        --prefix PATH : "${zenity}/bin" \
        --prefix PATH : "${openvpn}/bin" \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runtimeLibs} \
        --prefix LD_LIBRARY_PATH : "$out/lib"
    '';
  };

  # FHS environment wrapper that provides the expected certificate structure
  wrapped = buildFHSEnv {
    inherit pname version;

    runScript = writeShellScript "${pname}-wrapper.sh" ''
      # Create certificate directory structure expected by Azure VPN client
      mkdir -p /etc/ssl/certs
      
      # Add DigiCert Global Root G2 (primary cert used by Azure)
      cat <<'CERT_EOF' > /etc/ssl/certs/DigiCert_Global_Root_G2.pem
      ${digiCertGlobalRootG2}
      CERT_EOF

      # Add DigiCert Global Root CA (alternative)
      cat <<'CERT_EOF' > /etc/ssl/certs/DigiCert_Global_Root_CA.pem
      ${digiCertGlobalRootCA}
      CERT_EOF

      exec ${unpacked}/bin/${pname} "$@"
    '';

    extraBwrapArgs = [
      "--tmpfs /etc/ssl"
    ];

    meta = {
      description = "Microsoft Azure VPN Client";
      homepage = "https://azure.microsoft.com/en-us/services/vpn-gateway/";
      license = lib.licenses.unfree;
      platforms = [ "x86_64-linux" ];
      maintainers = [ ];
      mainProgram = "microsoft-azurevpnclient";
    };
  };
in
wrapped
