class DropboxController < ApplicationController

  # TODO: Move this to an OAuth provider
  def authorize
    if params[:oauth_token] then
      dropbox_session = Dropbox::Session.deserialize(session[:dropbox_session])
      dropbox_session.authorize(params)
      session[:dropbox_session] = dropbox_session.serialize # re-serialize the authenticated session

      redirect_to dropbox_path
    else
      dropbox_session = Dropbox::Session.new('fktumhugc62wybc', 'dx3oxh41fpd8xv4')
      dropbox_session.mode = :sandbox
      session[:dropbox_session] = dropbox_session.serialize
      redirect_to dropbox_session.authorize_url(:oauth_callback => url_for(:action => 'authorize'))
    end
  end

  # List all the files in one folder. Accepts paths like:
  # /dropbox              Lists all projects
  # /dropbox/org          Folders in an organization (projects)
  # /dropbox/org/project  Synced files for a project
  def ls
    return redirect_to(dropbox_authorize_path) unless session[:dropbox_session]
    dropbox = Dropbox::Session.deserialize(session[:dropbox_session])
    return redirect_to(dropbox_authorize_path) unless dropbox.authorized?

    path = params[:full_path] || "/"
    @files = dropbox.ls(path)
    @folders = path.split("/")
    @folders_without_last = @folders.dup
    @folders_without_last.pop
    @parent = @folders_without_last.try(:last)
  end

  # Pushes projects to the user's account
  def sync
    return redirect_to(dropbox_authorize_path) unless session[:dropbox_session]
    #dropbox = Dropbox::Session.deserialize(session[:dropbox_session])
    # TODO: Using a fake dropbox account for development
    dropbox = Dropbox::Session.deserialize("---\n- fktumhugc62wybc\n- dx3oxh41fpd8xv4\n- true\n- 5c0tk1jnemmgrel\n- eviyb1j79a5y19k\n- false")
    return redirect_to(dropbox_authorize_path) unless dropbox.authorized?

    # This sends every file to my Dropbox account
    # TODO: Don't send private elements
    current_user.projects.find_each do |project|
      project.uploads.find_each do |u|
        dest = "#{project.organization.permalink}/#{project.permalink}/"
        dropbox.upload "#{Rails.root}#{u.asset.url}", dest
      end
    end

    render :text => "done! #{session[:dropbox_session]}"
  end

end
