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

class ICodeReview
	def execute(path)
	end
end

class CppCheck < ICodeReview
	def initialize(options=nil)
		@options = options ? options.join(" ") : nil
	end
	def execute(path)
		if FileClassifier.getFileType(path) == FileClassifier::FORMAT_C then
			exec_cmd = "cppcheck #{Shellwords.shellescape(path)} #{@options}"
			return ExecUtil.getExecResultEachLine(exec_cmd, ".")
		end
		return []
	end
end

all_modified, result_to_be_commited, result_changes_not_staged, result_untracked = GitUtil.status(".")

checker = []
checker << CppCheck.new()


all_modified.each do |aFile|
	result = GitUtil.diff(".", "HEAD #{aFile}")
	if !result.empty? or result_to_be_commited.include?(aFile) then
		# actual modified file!
		checker.each do |aChecker|
			puts _checker = aChecker.execute( aFile )
		end
	end
end