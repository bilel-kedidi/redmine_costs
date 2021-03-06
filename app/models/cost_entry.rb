class CostEntry < ActiveRecord::Base
  unloadable

  include Redmine::SafeAttributes

  belongs_to :project
  belongs_to :issue
  belongs_to :user
  belongs_to :role
  belongs_to :time_entry
  belongs_to :activity, :class_name => 'CostEntryActivity', :foreign_key => 'activity_id'

  acts_as_customizable
  validates_presence_of :user_id, :project_id, :costs, :spent_on
  validates_numericality_of :costs, :allow_nil => true, :message => :invalid
  validates_length_of :comments, :maximum => 255, :allow_nil => true
  validates :spent_on, :date => true
  # validates :activity_id
  before_validation :set_project_if_nil
  before_validation :set_role_if_nil


  safe_attributes 'costs', 'comments', 'project_id', 'issue_id', 'activity_id', 'spent_on', 'time_entry_id'


  scope :visible, lambda {|*args|
                  if User.current.admin?
                    includes(:project)
                  else
                    includes(:project).where(user_id: User.current.id)
                  end
                }
  scope :on_issue, lambda {|issue|
                   includes(:issue).where("#{Issue.table_name}.root_id = #{issue.root_id} AND #{Issue.table_name}.lft >= #{issue.lft} AND #{Issue.table_name}.rgt <= #{issue.rgt}")
                 }
  scope :on_project, lambda {|project, include_subprojects|
                     includes(:project).where(project.project_condition(include_subprojects))
                   }
  scope :spent_between, lambda {|from, to|
                        if from && to
                          where("#{TimeEntry.table_name}.spent_on BETWEEN ? AND ?", from, to)
                        elsif from
                          where("#{TimeEntry.table_name}.spent_on >= ?", from)
                        elsif to
                          where("#{TimeEntry.table_name}.spent_on <= ?", to)
                        else
                          where(nil)
                        end
                      }

  def set_project_if_nil
    self.project = issue.project if issue && project.nil?
  end

  def set_role_if_nil
    self.role_id = set_role if self.role_id.nil?
  end

  def set_role
    member = project.members.where(user_id: user_id).first
    if member
      role = member.roles.first
      return role.id
    end
    nil
  end

  def editable_by?(usr)
    usr == user && usr.allowed_to?(:edit_own_cost_entries, project)
  end

  def safe_attributes=(attrs, user=User.current)
    if attrs
      attrs = super(attrs)
      if issue_id_changed? && attrs[:project_id].blank? && issue && issue.project_id != project_id
        if user.allowed_to?(:log_time, issue.project)
          self.project_id = issue.project_id
        end
      end
    end
    attrs
  end

  def hours=(h)
    write_attribute :costs, (h.is_a?(String) ? (h.to_f.round(2) || h) : h)
  end

  def costs
    h = read_attribute(:costs)
    if h.is_a?(Float)
      h.round(2)
    else
      h
    end
  end

  def hours
    if time_entry
      time_entry.hours
    else
      nil
    end
  end

  def spent_on=(date)
    super
    if spent_on.is_a?(Time)
      self.spent_on = spent_on.to_date
    end
    self.tyear = spent_on ? spent_on.year : nil
    self.tmonth = spent_on ? spent_on.month : nil
    self.tweek = spent_on ? Date.civil(spent_on.year, spent_on.month, spent_on.day).cweek : nil
  end

  def editable_custom_field_values(user=nil)
    visible_custom_field_values
  end

  # Returns the custom fields that can be edited by the given user
  def editable_custom_fields(user=nil)
    editable_custom_field_values(user).map(&:custom_field).uniq
  end

end
