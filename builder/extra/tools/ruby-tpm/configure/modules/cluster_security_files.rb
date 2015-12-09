module ClusterSecurityFiles
  def create_default_security_files(config)
    generate_tls = true
    
    # Backwards compatible section allows for the use of 
    # --java-truststore-path and --java-keystore-path
    
    ts = config.getProperty(JAVA_TRUSTSTORE_PATH)
    ks = config.getProperty(JAVA_KEYSTORE_PATH)
    
    if ts != nil && ks == nil
      Configurator.instance.error("Both --java-truststore-path and --java-keystore-path must be given together or not at all.")
    end
    if ts == nil && ks != nil
      Configurator.instance.error("Both --java-truststore-path and --java-keystore-path must be given together or not at all.")
    end
    if ts != nil && ks != nil
      generate_tls = false
    end
    
    # New section allows for the use of --java-tls-keystore-path
    tls_keystore = config.getProperty(JAVA_TLS_KEYSTORE_PATH)
    if tls_keystore != nil
      generate_tls = false
    end
    
    if generate_tls == true
      generate_tls_certificate(config)
    end
    
    if config.getProperty(JAVA_JGROUPS_KEYSTORE_PATH) == nil
      generate_jgroups_certificate(config)
    end
  end
  
  def generate_tls_certificate(config)
    ks_pass = config.getProperty(JAVA_KEYSTORE_PASSWORD)
    lifetime = config.getProperty(JAVA_TLS_KEY_LIFETIME)
    
    tls_ks = HostJavaTLSKeystorePath.build_keystore(
      staging_temp_directory(),
      config.getProperty(JAVA_TLS_ENTRY_ALIAS), ks_pass, ks_pass, lifetime
    )
    local_tls_ks = Tempfile.new("tlssec")
    local_tls_ks.close()
    local_tls_ks_path = "#{staging_temp_directory()}/#{File.basename(local_tls_ks.path())}"
    FileUtils.cp(tls_ks, local_tls_ks_path)
    
    config.include([HOSTS, config.getProperty([DEPLOYMENT_HOST])], {
      JAVA_TLS_KEYSTORE_PATH => "#{config.getProperty(TEMP_DIRECTORY)}/#{config.getProperty(CONFIG_TARGET_BASENAME)}/#{File.basename(local_tls_ks_path)}",
      GLOBAL_JAVA_TLS_KEYSTORE_PATH => local_tls_ks_path
    })
  end
  
  def generate_jgroups_certificate(config)
    ks_pass = config.getProperty(JAVA_KEYSTORE_PASSWORD)
    
    jgroups_ks = HostJavaJgroupsKeystorePath.build_keystore(
      staging_temp_directory(),
      config.getProperty(JAVA_JGROUPS_ENTRY_ALIAS), ks_pass, ks_pass
    )
    local_jgroups_ks = Tempfile.new("jgroupssec")
    local_jgroups_ks.close()
    local_jgroups_ks_path = "#{staging_temp_directory()}/#{File.basename(local_jgroups_ks.path())}"
    FileUtils.cp(jgroups_ks, local_jgroups_ks_path)
      
    config.include([HOSTS, config.getProperty([DEPLOYMENT_HOST])], {
      JAVA_JGROUPS_KEYSTORE_PATH => "#{config.getProperty(TEMP_DIRECTORY)}/#{config.getProperty(CONFIG_TARGET_BASENAME)}/#{File.basename(local_jgroups_ks_path)}",
      GLOBAL_JAVA_JGROUPS_KEYSTORE_PATH => local_jgroups_ks_path
    })
  end
  
  def staging_temp_directory
    Configurator.instance.command.get_temp_directory()
  end
end