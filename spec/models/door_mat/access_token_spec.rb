require 'spec_helper'

module DoorMat
  describe AccessToken do
    let(:admin) { {email: Rails.application.secrets.admin_account_email, password: Rails.application.secrets.admin_account_pwd} }
    let(:params) { {token_for: :big_ticket, identifier: 'user@example.com', confirm_identifier: 'user@example.com', name: 'User', is_public: '1', remember_me: '0'} }

    describe '#_url methods' do
      it 'returns an array of atoms' do
        DoorMat::TestHelper.create_signed_up_actor_with_confirmed_email_address(admin[:email], admin[:password])
        request = Object.new

        access_token = DoorMat::AccessToken.create_from_params(params[:token_for],
                                                               params[:identifier],
                                                               params[:confirm_identifier],
                                                               params[:name],
                                                               params[:is_public],
                                                               params[:remember_me],
                                                               request)

        # generic_redirect_url
        access_token.default_parameters[:generic_redirect_url] = [:a, :b]
        expect(access_token.generic_redirect_url).to eq([:a, :b])

        access_token.default_parameters.delete :generic_redirect_url
        expect(access_token.generic_redirect_url).to eq([:main_app, :root_url])


        # default_success_url
        expect(access_token.default_success_url).to eq([:main_app, :draw_results_url])

        access_token.default_parameters[:generic_redirect_url] = [:c, :d]
        access_token.session_parameters.delete :default_success_url
        expect(access_token.default_success_url).to eq([:c, :d])


        # default_failure_url
        access_token.default_parameters[:generic_redirect_url] = [:e, :f]
        expect(access_token.default_failure_url).to eq([:e, :f])

        access_token.session_parameters[:default_failure_url] = [:g, :h]
        expect(access_token.default_failure_url).to eq([:g, :h])

        access_token.default_parameters[:generic_redirect_url] = [:main_app, :root_url]
        access_token.session_parameters[:default_success_url] = [:main_app, :draw_results_url]
        access_token.session_parameters.delete :default_failure_url

      end

    end

    describe '#create_from_params' do

      it 'can not create an access_token when the actor for the session can not be loaded' do
        request = OpenStruct.new(:remote_ip => '127.0.0.1')

        access_token = DoorMat::AccessToken.create_from_params(params[:token_for],
                                                               params[:identifier],
                                                               params[:confirm_identifier],
                                                               params[:name],
                                                               params[:is_public],
                                                               params[:remember_me],
                                                               request)

        expect(access_token).not_to be_valid
      end

      it 'can create an access_token when the actor for the session can be loaded' do
        DoorMat::TestHelper.create_signed_up_actor_with_confirmed_email_address(admin[:email], admin[:password])
        request = Object.new

        access_token = DoorMat::AccessToken.create_from_params(params[:token_for],
                                                               params[:identifier],
                                                               params[:confirm_identifier],
                                                               params[:name],
                                                               params[:is_public],
                                                               params[:remember_me],
                                                               request)

        expect(access_token).to be_valid
      end

      it 'can not create an access_token if the status is not valid' do
        DoorMat::TestHelper.create_signed_up_actor_with_confirmed_email_address(admin[:email], admin[:password])
        original_value = DoorMat.configuration.password_less_sessions[params[:token_for].to_sym][:status]
        DoorMat.configuration.password_less_sessions[params[:token_for].to_sym][:status] = :invalid
        request = OpenStruct.new(:remote_ip => '127.0.0.1')

        access_token = DoorMat::AccessToken.create_from_params(params[:token_for],
                                                               params[:identifier],
                                                               params[:confirm_identifier],
                                                               params[:name],
                                                               params[:is_public],
                                                               params[:remember_me],
                                                               request)

        expect(access_token.errors.full_messages.join('')).to match(/Could not create a request token based on the information provided/)
        expect(access_token).not_to be_valid
        DoorMat.configuration.password_less_sessions[params[:token_for].to_sym][:status] = original_value
      end

    end

    describe '#swap_token!' do

      it 'swaps an existing token for a new one' do
        DoorMat::TestHelper.create_signed_up_actor_with_confirmed_email_address(admin[:email], admin[:password])
        request = Object.new

        access_token = DoorMat::AccessToken.create_from_params(params[:token_for],
                                                               params[:identifier],
                                                               params[:confirm_identifier],
                                                               params[:name],
                                                               params[:is_public],
                                                               params[:remember_me],
                                                               request)

        access_token.used!
        expect(access_token).to be_valid
        RequestStore.store[:current_access_token] = access_token

        cookies = Object.new
        allow(cookies).to receive(:encrypted).and_return({})

        DoorMat::AccessToken.swap_token!(cookies, :big_ticket, :play_game, true)

        expect(access_token.destroyed?).to be_truthy
        expect(RequestStore.store[:current_access_token]).to be_valid
      end

    end

  end
end
