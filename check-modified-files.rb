#!/usr/bin/ruby

# Copyright 2023 hidenorly
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require_relative 'GitUtil'
require_relative 'ExecUtil'
require "shellwords"
require 'optparse'

class ICodeReview
	def execute(path)
	end
end

class CppCheck < ICodeReview
	def initialize(options=nil)
		@options = options.to_s
	end
	def execute(path)
		if FileClassifier.getFileType(path) == FileClassifier::FORMAT_C then
			exec_cmd = "cppcheck #{Shellwords.shellescape(path)} #{@options}"
			return ExecUtil.getExecResultEachLine(exec_cmd, ".")
		end
		return []
	end
end

class Infer < ICodeReview
	def initialize(options=nil)
		@options = options.to_s
	end
	def execute(path)
		case FileClassifier.getFileType(path)
		when FileClassifier::FORMAT_C then
			exec_cmd = "infer capture -- clang -c #{Shellwords.shellescape(path)} #{@options}"
			ExecUtil.getExecResultEachLine(exec_cmd, ".")
			exec_cmd = "infer analyze -- clang -c #{Shellwords.shellescape(path)} #{@options}"
			return ExecUtil.getExecResultEachLine(exec_cmd, ".")
		when FileClassifier::FORMAT_JAVA then
			#exec_cmd = "infer run -- javac #{Shellwords.shellescape(path)} #{@options}"
			#return ExecUtil.getExecResultEachLine(exec_cmd, ".")
		end
		return []
	end
end

#---- main --------------------------
options = {
	:all => false,
	:cppcheck => nil,
}

opt_parser = OptionParser.new do |opts|
	opts.banner = "Usage: execute this in the git folder's root"

	opts.on("-a", "--all", "Specify if you want to apply all modified files") do
		options[:all] = true
	end

	opts.on("-c", "--cppcheck=", "Specify option for cppcheck (default:#{options[:cppcheck]}) e.g. --enable=all") do |cppcheck|
		options[:cppcheck] = cppcheck
	end
end.parse!


all_modified, result_to_be_commited, result_changes_not_staged, result_untracked = GitUtil.status(".")

checker = []
checker << CppCheck.new(options[:cppcheck])
checker << Infer.new()


all_modified.each do |aFile|
	result = GitUtil.diff(".", "HEAD #{aFile}")
	if options[:all] or !result.empty? or result_to_be_commited.include?(aFile) then
		# actual modified file!
		checker.each do |aChecker|
			puts _checker = aChecker.execute( aFile )
		end
	end
end
