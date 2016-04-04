

# Generic steps

def wait_two_minutes
  t = 2.minutes.from_now
  Timecop.travel(t)
end

def wait_two_days
  t = 2.days.from_now
  Timecop.travel(t)
end


# public computer timeout

def wait_longer_than_public_computer_session_timeout
  t = (DoorMat.configuration.public_computer_access_session_timeout + 1).minutes.from_now
  Timecop.travel(t)
end

def wait_less_than_public_computer_session_timeout
  t = (DoorMat.configuration.public_computer_access_session_timeout - 1).minutes.from_now
  Timecop.travel(t)
end


# private computer timeout

def wait_longer_than_private_computer_session_timeout
  t = (DoorMat.configuration.private_computer_access_session_timeout + 1).minutes.from_now
  Timecop.travel(t)
end

def wait_less_than_private_computer_session_timeout
  t = (DoorMat.configuration.private_computer_access_session_timeout - 1).minutes.from_now
  Timecop.travel(t)
end


# remember me timeout

def wait_longer_than_remember_me_timeout
  t = (DoorMat.configuration.remember_me_max_day_count + 1).day.from_now
  Timecop.travel(t)
end

def wait_less_than_remember_me_timeout
  t = (DoorMat.configuration.remember_me_max_day_count - 1).day.from_now
  Timecop.travel(t)
end
