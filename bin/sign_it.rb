#!/usr/bin/env ruby

#run this from the repo root directory. 
#It is meant for the github action
require "json"
require "openssl"
require "base64"

private_key = OpenSSL::PKey::RSA.new(ENV.fetch("PRIVATE_KEY"))
digest = OpenSSL::Digest.new("SHA1") 

repository = JSON.load_file("./repo/repository.json")
repository.each do | plugin |
  plugin["versions"].each do |version|
    version["artifacts"].each do | jar |
      signature = Base64.encode64(private_key.sign(digest, File.read(jar["url"]))).gsub("\n","")
      jar["sig"] = signature
    end
  end
end

File.write"./repo/repository.json", JSON.pretty_generate(repository)
