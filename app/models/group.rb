class Group < ActiveRecord::Base
  include LogHelper

  belongs_to :group_set
  belongs_to :tutorial

  has_many :group_memberships
  has_many :group_submissions
  has_many :projects, -> { where("group_memberships.active = :value and projects.enrolled = true", value: true) }, through: :group_memberships
  has_many :past_projects, -> { where("group_memberships.active = :value", value: false) },  through: :group_memberships, source: 'project'
  has_one :unit, through: :group_set
  has_one :tutor, through: :tutorial

  validates :name, presence: true, allow_nil: false
  validates :group_set, presence: true, allow_nil: false
  validates :tutorial, presence: true, allow_nil: false
  validates_associated :group_memberships
  validates :name, uniqueness: { scope: :group_set,
    message: "must be unique within the set of groups" }
  validate :must_be_in_same_tutorial, if: :limit_members_to_tutorial?

  before_destroy :ensure_no_submissions

  #
  # Permissions around group data
  #
  def self.permissions
    # What can students do with groups?
    student_role_permissions = [
      :get_members
    ]
    # What can tutors do with groups?
    tutor_role_permissions = [
      :get_members,
      :manage_group
    ]
    # What can convenors do with groups?
    convenor_role_permissions = [
      :get_members,
      :manage_group
    ]
    # What can nil users do with groups?
    nil_role_permissions = [

    ]

    # Return permissions hash
    {
      :convenor => convenor_role_permissions,
      :tutor    => tutor_role_permissions,
      :student  => student_role_permissions,
      :nil      => nil_role_permissions
    }
  end

  def ensure_no_submissions()
    return true if group_submissions.count == 0
    self.errors[:base] << "Cannot delete group while it has submissions."
    return false
  end

  def specific_permission_hash(role, perm_hash, other)
    result = perm_hash[role] unless perm_hash.nil?
  if result && role == :student
      if group_set.allow_students_to_manage_groups
        result << :manage_group
      end
    end
    result
  end

  def role_for(user)
    result = unit.role_for(user)
    if result == Role.student
      result = nil unless has_user user
    end

    result
  end

  def has_user(user)
    projects.where("user_id = :user_id", user_id: user.id).count == 1
  end

  def add_member(project)
    gm = project.group_membership_for_groupset(group_set)

    if gm.nil?
      gm = GroupMembership.create(group: self, project:project)
    else
      gm = GroupMembership.find(gm.id)
      gm.group = self
    end

    gm.active = true
    gm.save!

    gm
  end

  def remove_member(project)
    gm = group_memberships.where(project: project).first
    gm.active = false
    gm.save
    self
  end

  #
  # check if the project is the same as the current submission
  #
  def __different_project_composition__ (contributors, gs)
    logger.debug "Starting checks"
    contributors.each do |contrib|
      logger.debug "-- Checking #{contrib}"
      return true unless gs.projects.include? contrib[:project]
      return true unless contrib[:pct].to_i > 0
    end
    logger.debug "Checking #{contributors.count} == #{gs.projects.count}"
    return contributors.count != gs.projects.count
  end

  #
  # The submitter task is the user who submitted this group task.
  #
  # Creates a Group Submission
  # Locates other group members, and link to this submission.
  #   - contributors contains [ {project: ..., pct: ... } ]
  #
  def create_submission(submitter_task, notes, contributors)
    total = 0
    #check all members are in the same group
    contributors.each do |contrib|
      project = contrib[:project]
      pct = contrib[:pct].to_i
      if pct < 0
        contrib[:pct] = 0
      else
        total += pct
      end
      raise "Not all contributions were from team members." unless projects.include? project
    end

    # check for all group members
    raise 'Contributions missing for some group members' unless projects.count == contributors.count

    # check pct
    raise 'Contribution percentages are insufficient.' unless total >= 90
    raise 'Contribution percentages are excessive.' unless total <= 110

    # check group task
    raise "Group submission only allowed for group tasks." unless submitter_task.task_definition.group_set
    raise "Group submission for wrong group for unit." unless submitter_task.task_definition.group_set == group_set

    old_gs = submitter_task.group_submission
    gs = old_gs
    if gs.nil? || __different_project_composition__(contributors, gs)
      gs = GroupSubmission.create()
      gs.task_definition = submitter_task.task_definition
    end

    gs.group = self
    gs.notes = notes
    gs.submitted_by_project = submitter_task.project
    gs.save!

    contributors.each do |contrib|
      project = contrib[:project]
      task = project.matching_task submitter_task

      if contrib[:pct].to_i > 0
        task.group_submission = gs
        task.contribution_pct = contrib[:pct]
      end
      task.save
    end

    if old_gs
      old_gs.reload
      if old_gs.projects.count == 0
        old_gs.destroy!
      end
    end

    #ensure that original task is reloaded... update will have effected a different object
    submitter_task.reload
    gs
  end

  def limit_members_to_tutorial?
    group_set.keep_groups_in_same_class
  end

  def must_be_in_same_tutorial
    if limit_members_to_tutorial?
      if ! all_members_in_tutorial?
        errors.add(:members, "must all be in the group's tutorial")
      end
    end
  end

  #
  # Check if all members are in this groups tutorial
  #
  def all_members_in_tutorial?
    group_memberships.each do |member|
      return false unless (not member.active) || member.in_group_tutorial?(self.tutorial)
    end
    return true
  end
end
