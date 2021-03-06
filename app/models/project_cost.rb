class ProjectCost < ActiveRecord::Base
  unloadable
  belongs_to :project

  def self.create_or_update_cost_entry(time_entry)
    ce = CostEntry.where(time_entry_id: time_entry.id).first_or_initialize
    ce.project_id = time_entry.project_id
    ce.issue_id = time_entry.issue_id
    ce.spent_on = time_entry.spent_on
    activity = CostEntryActivity.shared.active.detect{|c| c.is_default }
    ce.activity_id = activity.id if activity
    ce.user_id = time_entry.user_id
    ce.time_entry_id = time_entry.id
    project = time_entry.project
    if project
      user = time_entry.user
        pc = ProjectCost.where(project_id: project.id).detect{|c| c.user_id = user.id}
        if pc
          ce.costs = pc.cost * time_entry.hours
          ce.save
        end
    end
  end
  
end
