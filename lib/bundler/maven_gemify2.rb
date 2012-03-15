require 'uri'
require 'tempfile'
require 'fileutils'
require 'rubygems'
require 'rubygems/builder'
require 'rubygems/installer'
require 'set'

# Amit Nithianandan
# ANithian-at-gmail.com 2/01/2012
# A modified maven_gemify that relies on the underlying Maven dependency 
# plugin to generate the proper classpath. Instead of downloading and packaging
# the jar inside the gem, make a ruby file require the jar file that already exists
# in the existing maven repo. This is handy in cases where java and ruby projects are simultaneously
# deployed across an organization and servers have mounted both a common maven repo AND a common gem
# mount. 
module Gem

  class Maven3NotFound < StandardError; end

  #A simple sub-class of the Specification that stores the "original" bundler
  #name of the gem. This name is not compatible with most file systems and is a pain
  #to require (require 'mvn:something:something' is ugly compared to require 'something_something')
  #Since this maven_gemify gets called multiple times, it's necessary to make sure that the original
  #name is preserved. This could rather store the maven group/artifact id so as to not keep parsing the 
  #original name over and over again.
  class MavenSpec < Gem::Specification
    attr_reader :orig_name
    def orig_name=(orig_name)
      @orig_name=orig_name
    end
  end

  module Maven
    
    class Gemify2
      attr_reader :repositories

      #repositories should be an array of urls
      def initialize(*repositories)
        maven                   # ensure maven initialized
        @repositories = Set.new
        if repositories.length > 0
          @repositories.merge([repositories].flatten)
        end
        
      end

      def add_repository(repository_url)
        @repositories << repository_url
      end
      
      @@verbose = false
      def self.verbose?
        @@verbose || $DEBUG
      end
      def verbose?
        self.class.verbose?
      end
      def self.verbose=(v)
        @@verbose = v
      end

      private
      def self.maven_config
        @maven_config ||= Gem.configuration["maven"] || {}
      end
      def maven_config; self.class.maven_config; end

      def self.java_imports
        %w(
           org.codehaus.plexus.classworlds.ClassWorld
           org.codehaus.plexus.DefaultContainerConfiguration
           org.codehaus.plexus.DefaultPlexusContainer
           org.apache.maven.Maven
           org.apache.maven.repository.RepositorySystem
           org.apache.maven.execution.DefaultMavenExecutionRequest
           org.apache.maven.artifact.repository.MavenArtifactRepository
           org.apache.maven.artifact.repository.layout.DefaultRepositoryLayout
           org.apache.maven.artifact.repository.ArtifactRepositoryPolicy
           javax.xml.stream.XMLStreamWriter
           javax.xml.stream.XMLOutputFactory
           javax.xml.stream.XMLStreamException
          ).each {|i| java_import i }
      end

      def self.create_maven
        require 'java' # done lazily, so we're not loading it all the time
        bin = nil
        if ENV['M2_HOME'] # use M2_HOME if set
          bin = File.join(ENV['M2_HOME'], "bin")
        else
          ENV['PATH'].split(File::PATH_SEPARATOR).detect do |path|
            mvn = File.join(path, "mvn")
            if File.exists?(mvn)
              if File.symlink?(mvn)
                link = File.readlink(mvn)
                if link =~ /^\// # is absolute path
                  bin = File.dirname(File.expand_path(link))
                else # is relative path so join with dir of the maven command
                  bin = File.dirname(File.expand_path(File.join(File.dirname(mvn), link)))
                end
              else # is no link so just expand it
                bin = File.expand_path(path)
              end
            else
              nil
            end
          end
        end
        bin = "/usr/share/maven2/bin" if bin.nil? # OK let's try debian default
        if File.exists?(bin)
          @mvn = File.join(bin, "mvn")
          if Dir.glob(File.join(bin, "..", "lib", "maven-core-3.*jar")).size == 0
            begin
              gem 'ruby-maven', ">=0"
              bin = File.dirname(Gem.bin_path('ruby-maven', "rmvn"))
              @mvn = File.join(bin, "rmvn")
            rescue LoadError
              bin = nil
            end
          end
        else
          bin = nil
        end
        raise Gem::Maven3NotFound.new("can not find maven3 installation. install ruby-maven with\n\n\tjruby -S gem install ruby-maven\n\n") if bin.nil?

        warn "Using Maven install at #{bin}" if verbose?

        boot = File.join(bin, "..", "boot")
        lib = File.join(bin, "..", "lib")
        ext = File.join(bin, "..", "ext")
        (Dir.glob(lib + "/*jar")  + Dir.glob(boot + "/*jar")).each {|path| require path }

        java.lang.System.setProperty("classworlds.conf", File.join(bin, "m2.conf"))
        java.lang.System.setProperty("maven.home", File.join(bin, ".."))
        java_imports

        class_world = ClassWorld.new("plexus.core", java.lang.Thread.currentThread().getContextClassLoader());
        config = DefaultContainerConfiguration.new
        config.set_class_world class_world
        config.set_name "ruby-tools"
        container = DefaultPlexusContainer.new(config);
        @@execution_request_populator = container.lookup(org.apache.maven.execution.MavenExecutionRequestPopulator.java_class)

        @@settings_builder = container.lookup(org.apache.maven.settings.building.SettingsBuilder.java_class )
        container.lookup(Maven.java_class)
      end

      def self.maven
        @maven ||= create_maven
      end
      def maven; self.class.maven; end

      def self.temp_dir
        @temp_dir ||=
          begin
            d=Dir.mktmpdir
            at_exit {FileUtils.rm_rf(d.dup)}
            d
          end
      end
      
      def temp_dir
        self.class.temp_dir
      end

      def execute(goals, pomFile,props = {})
        request = DefaultMavenExecutionRequest.new
        request.set_show_errors(true)

        props.each do |k,v|
          request.user_properties.put(k.to_s, v.to_s)
        end
        request.set_goals(goals)
        request.set_logging_level 0
        request.setPom(java.io.File.new(pomFile))
        if verbose?
          active_profiles = request.getActiveProfiles.collect{ |p| p.to_s }
          puts "active profiles:\n\t[#{active_profiles.join(', ')}]"
          puts "maven goals:"
          request.goals.each { |g| puts "\t#{g}" }
          puts "system properties:"
          request.getUserProperties.map.each { |k,v| puts "\t#{k} => #{v}" }
          puts
        end
        out = java.lang.System.out
        string_io = java.io.ByteArrayOutputStream.new
        java.lang.System.setOut(java.io.PrintStream.new(string_io))
        result = maven.execute request
        java.lang.System.out = out
        has_exceptions = false
        result.exceptions.each do |e|
          has_exceptions = true
          e.print_stack_trace
          string_io.write(e.get_message.to_java_string.get_bytes)
        end
        raise string_io.to_s if has_exceptions
        string_io.to_s
      end

      def writeElement(xmlWriter,element_name, text)
        xmlWriter.writeStartElement(element_name.to_java)
        xmlWriter.writeCharacters(text.to_java)
        xmlWriter.writeEndElement        
      end
      
      public
      def maven_name(gemname)
        self.class.mname(gemname)
      end
      #gemname==mvn:group_id:artifact_id
      def self.mname(gemname)
        gemname.gsub("mvn:","").gsub(".","_").gsub(":","_")
      end
            
      def get_versions(gemname)
        []
      end

      def generate_spec(gemname, version)
        mname = maven_name(gemname)
        MavenSpec.new do |s|
          s.name        = mname
          s.orig_name = gemname          
          s.date        = '2010-04-28'
          s.summary     = "Hola!"
          s.description = "A simple hello world gem"
          s.authors     = ["Nick Quaranto"]
          s.email       = 'nick@quaran.to'
          s.homepage    = 'http://rubygems.org/gems/hola'       
          s.version     = version
          s.files       = "lib/#{mname}.rb"
        end
      end
      
      def generate_gem(gemname, version)
        mname = maven_name(gemname)
        spec_file=generate_spec(gemname,version)
        # spec_file.name=mname #So that the gem's name is correct
        gemname=gemname.gsub("mvn:","")
        maven_parts = gemname.split(":")
        group_id = maven_parts[0]
        artifact_id = maven_parts[1]
        
        FileUtils.mkdir_p(File.join(temp_dir,"lib"))
        #Generate a dummy POM file that we'll use to run maven against
        #to resolve deps and generate a classpath
        pomfile=File.join(temp_dir,"pom.xml")
        puts "pomfile=#{pomfile}"
        out = java.io.BufferedOutputStream.new(java.io.FileOutputStream.new(pomfile.to_java))
        outputFactory = XMLOutputFactory.newFactory()
        xmlStreamWriter = outputFactory.createXMLStreamWriter(out)
        xmlStreamWriter.writeStartDocument
        xmlStreamWriter.writeStartElement("project".to_java)
        
        writeElement(xmlStreamWriter,"groupId","org.hokiesuns.mavengemify")
        writeElement(xmlStreamWriter,"artifactId","mavengemify")
        writeElement(xmlStreamWriter,"modelVersion","4.0.0")
        writeElement(xmlStreamWriter,"version","1.0-SNAPSHOT")
                          
        #Repositories
        if @repositories.length > 0
          xmlStreamWriter.writeStartElement("repositories".to_java)
          @repositories.each_with_index {|repo,i|
            xmlStreamWriter.writeStartElement("repository".to_java)
            writeElement(xmlStreamWriter,"id","repository_#{i}")
            writeElement(xmlStreamWriter,"url",repo)
            xmlStreamWriter.writeEndElement #repository
            }
          xmlStreamWriter.writeEndElement #repositories
        end                                
        xmlStreamWriter.writeStartElement("dependencies".to_java)
        
        xmlStreamWriter.writeStartElement("dependency".to_java)
        writeElement(xmlStreamWriter,"groupId",group_id)
        writeElement(xmlStreamWriter,"artifactId",artifact_id)
        writeElement(xmlStreamWriter,"version",version.to_s)
    
        xmlStreamWriter.writeEndElement #dependency
        
        xmlStreamWriter.writeEndElement #dependencies
                
        xmlStreamWriter.writeEndElement #project
        
        xmlStreamWriter.writeEndDocument
        xmlStreamWriter.close
        out.close

        execute(["dependency:resolve","dependency:build-classpath"],pomfile,{"mdep.outputFile" => "cp.txt","mdep.fileSeparator"=>"/"})
        
        ruby_file = File.new(File.join(temp_dir,"lib/#{mname}.rb"),"w")
        cp_file = File.new(File.join(temp_dir,"cp.txt"),"r")
        cp_line = cp_file.gets
        cp_file.close
        cp_entries = cp_line.split(";")
        cp_entries.each{ |entry|
          ruby_file.puts "require \"#{entry}\""
        }
        ruby_file.close
        old_pwd = Dir.pwd
        Dir.chdir(temp_dir)
        gembuilder = Gem::Builder.new(spec_file)
        gemfile=gembuilder.build
        
        geminstaller = Gem::Installer.new(gemfile)
        geminstaller.install
        Dir.chdir(old_pwd)
      end
      
    end
  end
end
