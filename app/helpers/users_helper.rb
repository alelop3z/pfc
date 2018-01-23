module UsersHelper

  def my_follows(_user = @current_user)
    _follows = User.only(:id, :name, :about_me, :avatar_file_name, :avatar_updated_at).where(:id.in => _user.follow_ids).shuffle[0..2]
    render :partial => "users/my_follows", :locals => {:follows => _follows}
  end

  def my_followers(_user = @current_user)
    _followers = User.only(:id, :name, :about_me, :avatar_file_name, :avatar_updated_at).where(:id.in => _user.follower_ids).shuffle[0..2]
    render :partial => "users/my_followers", :locals => {:followers => _followers}
  end

  def my_suggest_follows(_user = @current_user)
    _suggest_follows = []
    render :partial => "users/my_suggest_friends", :locals => {:suggest_friends => _suggest_friends}
  end

end
