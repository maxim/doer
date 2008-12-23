#!/usr/bin/ruby
class DoerException < Exception; end

load 'dofile'

class Doer
  class << self
    def run(who, what, args)
      command = find_cmd(who, what)
      templates, replacements = normalize_cmd(who, command)
      commands = apply_replacements(templates, replacements, args)
      
      puts "------------ #{who.to_s.upcase} #{what.to_s.upcase} ------------\n"
      commands.each do |cmd|
        cmd.class == Proc ? cmd.call : system(cd_here(who, cmd))
      end
      puts "\n\n"
    rescue DoerException => e
      puts e.message
      exit
    end
    
    private
    def cd_here(who, cmd)
      "cd #{HERE}/#{who} && #{cmd}"
    end
    
    def normalize_cmd(project, command)
      commands = []
      replacements = []
      
      command.each do |token|
        if token.class == Symbol
          c = find_cmd(project, token)
          ref_cmds, ref_replacements = normalize_cmd(project, c)
          commands += ref_cmds
          replacements += ref_replacements
          
        elsif token.class == Array
          replacements += token
        
        elsif token.class == String
          commands << token
        
        elsif token.class == Proc
          commands << token
        end
      end
      
      return commands, replacements
    end
    
    def find_cmd(project, command)
      raise(DoerException, "No such project \"#{project}\"") unless PROJECTS.key?(project)
      cmd = PROJECTS[project][command] || PROJECTS[:default][command] || raise(DoerException, "No such command \"#{command}\"")
      cmd = [cmd] unless cmd.class == Array
      cmd
    end
    
    def apply_replacements(templates, tokens, args)
      tpls = templates.dup
      
      args.size.times do |i|
        token = ':' + tokens[i].to_s
        replacement = args[i].to_s
        tpls = tpls.collect do |tpl|
          tpl.class == String ? tpl.gsub(token, replacement) : tpl
        end
      end
      
      tpls
    end
  end
end

input = ARGV

what  = input.shift
who   = input.shift
args  = input

what = what.downcase.to_sym
if (!who || who == 'all')
  (PROJECTS.keys - [:default]).each{|p| Doer::run(p, what, args)}
else
  who = who.downcase.to_sym
  Doer::run(who, what, args)
end