#!/usr/bin/ruby

# Copyright 2023, 2024 hidenorly
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
	def self._isAvailable(command)
		exec_cmd = "which #{Shellwords.shellescape(command)}"
		result = ExecUtil.getExecResultEachLine(exec_cmd, ".")
		return !result.include?("not found")
	end
	def self.isAvailable()
		return false
	end
	def execute(path)
		return []
	end
end

class CppCheck < ICodeReview
	def initialize(options=nil)
		@options = options.to_s
	end

	def self.isAvailable()
		return _isAvailable("cppcheck")
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
	def initialize(optionsCapture=nil, optionsAnalyze=nil)
		@optionsCapture = optionsCapture.to_s
		@optionsAnalyze = optionsAnalyze.to_s
	end

	def self.isAvailable()
		return _isAvailable("infer")
	end

	def execute(path)
		case FileClassifier.getFileType(path)
		when FileClassifier::FORMAT_C then
			exec_cmd = "infer capture -- clang #{@optionsCapture} -c #{Shellwords.shellescape(path)}"
			ExecUtil.getExecResultEachLine(exec_cmd, ".")
			exec_cmd = "infer analyze -- clang #{@optionsAnalyze} -c #{Shellwords.shellescape(path)}"
			return ExecUtil.getExecResultEachLine(exec_cmd, ".")
		when FileClassifier::FORMAT_JAVA then
			#exec_cmd = "infer run -- javac #{Shellwords.shellescape(path)} #{@options}"
			#return ExecUtil.getExecResultEachLine(exec_cmd, ".")
		end
		return []
	end
end

class LlmReview < ICodeReview
	FILE_LLM_REVIEW = "llm-review.py"
	def initialize(options=nil)
		@options = options.to_s
	end

	def self.isAvailable()
		return File.exist?(FILE_LLM_REVIEW)
	end

	def execute(path)
		exec_cmd = "python3 #{FILE_LLM_REVIEW} #{Shellwords.shellescape(path)} #{@options}"
		return ExecUtil.getExecResultEachLine(exec_cmd, ".")
	end
end

#---- main --------------------------
options = {
	:all => false,
	:cppcheck => nil,
	:inferCapture => nil,
	:inferAnalyze => nil
}

opt_parser = OptionParser.new do |opts|
	opts.banner = "Usage: execute this in the git folder's root"

	opts.on("-a", "--all", "Specify if you want to apply all modified files") do
		options[:all] = true
	end

	opts.on("-c", "--cppcheck=", "Specify option for cppcheck (default:#{options[:cppcheck]}) e.g. --enable=all") do |cppcheck|
		options[:cppcheck] = cppcheck
	end

	opts.on("", "--inferCapture=", "Specify option for infer on the capture command (default:#{options[:inferCapture]})") do |inferCapture|
		options[:inferCapture] = inferCapture
	end

	opts.on("", "--inferAnalyze=", "Specify option for infer on the analyze command (default:#{options[:inferAnalyze]})") do |inferAnalyze|
		options[:inferAnalyze] = inferAnalyze
	end
end.parse!


all_modified, result_to_be_commited, result_changes_not_staged, result_untracked = GitUtil.status(".")

checker = []
checker << CppCheck.new(options[:cppcheck]) if CppCheck.isAvailable()
checker << Infer.new(options[:inferCapture], options[:inferAnalyze]) if Infer.isAvailable()
checker << LlmReview.new() if LlmReview.isAvailable()


all_modified.each do |aFile|
	result = GitUtil.diff(".", "HEAD #{aFile}")
	if options[:all] or !result.empty? or result_to_be_commited.include?(aFile) then
		# actual modified file!
		checker.each do |aChecker|
			puts _checker = aChecker.execute( aFile )
		end
	end
end
