class Game < ActiveRecord::Base
  include DoorMat::AttrSymmetricStore

  belongs_to :actor, class_name: 'DoorMat::Actor'

  attr_symmetric_store :state

  def self.init_for_actor_and_doors(actor, door_count)
    game = Game.new
    game.actor = actor
    game.state = [
        door_count, # doors
        Array(1 .. door_count).sample, # winning door
        0, # player selected door
        0  # loosing door shown
    ].join(':')
    game
  end

  def number_of_doors
    get_at(0)
  end
  def winning_door
    get_at(1)
  end
  def player_selected_door
    get_at(2)
  end
  def loosing_door_shown
    get_at(3)
  end

  def player_select_door!(door_number)
    raise "Invalid door number selected" unless ((door_number.to_i > 0) && (door_number.to_i <= number_of_doors))
    set_at(2, door_number)
  end

  def host_select_loosing_door
    return unless 0 == loosing_door_shown
    available_doors = Array(1 .. number_of_doors)
    available_doors.delete(winning_door)
    available_doors.delete(player_selected_door)
    set_at(3, available_doors.sample)
  end

  def player_win?
    winning_door == player_selected_door
  end

  private

  def get_at(i)
    self.state.split(':')[i].to_i
  end

  def set_at(i, value)
    state = self.state.split(':')
    state[i] = value.to_s
    self.state = state.join(':')
  end

end
