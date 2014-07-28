# encoding: UTF-8

# $HeadURL$
# $Id$
#
# Copyright (c) 2009-2014 by Public Library of Science, a non-profit corporation
# http://www.plos.org/
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

class Group < ActiveRecord::Base
  has_many :sources, :order => "display_name", :dependent => :nullify

  validates :name, :presence => true, :uniqueness => true
  validates :display_name, :presence => true

  scope :visible, joins(:sources).where("state > ?", 1).order("groups.id")
  scope :with_sources, joins(:sources).order("groups.id")
end
