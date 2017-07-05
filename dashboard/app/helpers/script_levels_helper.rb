module ScriptLevelsHelper
  def script_level_solved_response(script_level, user)
    if user
      _solved_response(script_level, user)
    else
      # Cache solved responses for anonymous users.
      key = "#{script_level.cache_key}/solved_response/#{I18n.locale}"
      Rails.cache.fetch(key, expires_in: 10.minutes) do
        _solved_response(script_level)
      end
    end
  end

  def _solved_response(script_level, user=nil)
    response = {}
    next_user_redirect = script_level.next_level_or_redirect_path_for_user user

    if script_level.has_another_level_to_go_to?
      if script_level.end_of_stage?
        response[:stage_changing] = {previous: {name: script_level.name, position: script_level.stage.absolute_position}}

        # End-of-Stage Experience is only enabled for:
        # stages except for the last stage of a script
        # users in sections with an enabled "stage extras" flag
        enabled_for_stage = !script_level.end_of_script?
        enabled_for_user = user.try(:section_for_script, script_level.script).try(:stage_extras)
        response[:end_of_stage_experience] = enabled_for_stage && enabled_for_user
      end
    else
      response[:message] = 'no more levels' # used by blockly to show a different feedback message on the last level

      if script_level.script.wrapup_video
        response[:video_info] = wrapup_video_then_redirect_response(
          script_level.script.wrapup_video,
          next_user_redirect
        )
        return
      end
    end

    response[:redirect] = next_user_redirect
    response
  end

  def wrapup_video_then_redirect_response(wrapup_video, redirect)
    video_info_response = wrapup_video.summarize
    video_info_response[:redirect] = redirect
    video_info_response
  end

  def script_completion_redirect(script)
    if script.hoc?
      script.hoc_finish_url
    elsif script.csf?
      script.csf_finish_url
    else
      root_path
    end
  end

  def tracking_pixel_url(script)
    if script.name == Script::HOC_2013_NAME
      CDO.code_org_url '/api/hour/begin_codeorg.png'
    else
      CDO.code_org_url "/api/hour/begin_#{script.name}.png"
    end
  end
end
