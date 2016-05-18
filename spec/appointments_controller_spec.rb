require 'spec_helper'

describe AppointmentsController do
  login_user
  

  def valid_attributes
    {:start_at => DateTime.now}
  end

  before(:each) do
    @client = FactoryGirl.create(:user)
    controller.stub!(:current_user).and_return(@user)
  end

  describe "Creating a new appointment as a trainer" do
     it "should only allow a client's trainer to create an appointment for them" do
       @user.stub(:trainer?).and_return(true)
       post :create, :appointment => valid_attributes, :client_id => @client.id
       flash[:error].should_not be_nil
       response.should render_template("new")
     end

     it "should allow a client's current trainer to create an appointment for them" do
       @user.stub(:trainer?).and_return(true)
       @user.stub(:plan).and_return(FactoryGirl.create :plan, client_slots: 10)
       @client.add_trainer(@user)
       post :create, :appointment => valid_attributes, :client_id => @client.id
       @client.appointments.should include(assigns(:appointment))
     end

     it "shouldn't allow a non-trainer to create an appointment" do
       post :create, :appointment => valid_attributes, :client_id => @client.id
       flash[:error].should_not be_nil
       response.should redirect_to(root_path)
     end
  end

  describe "GET index" do
    before(:each) do
      @user.stub(:trainer?).and_return(true)
    end

    it "assigns all appointments as @appointments" do
      appointment = FactoryGirl.create(:appointment, trainer: @user)
      get :index
      assigns(:appointments).should eq([appointment])
    end
  end

  describe "GET show" do
    before(:each) do
      @user.stub(:trainer?).and_return(true)
    end

    it "assigns the requested appointment as @appointment" do
      appointment = FactoryGirl.create(:appointment, trainer: @user)
      get :show, :id => appointment.id.to_s
      assigns(:appointment).should eq(appointment)
    end
  end

  describe "GET new" do
    before(:each) do
      @user.stub(:trainer?).and_return(true)
    end

    it "assigns a new appointment as @appointment" do
      get :new
      assigns(:appointment).should be_a_new(Appointment)
    end
  end

  describe "GET edit" do
    it "assigns the requested appointment as @appointment" do
      @user.stub(:trainer?).and_return(true)
      appointment = FactoryGirl.create(:appointment, trainer: @user)
      get :edit, :id => appointment.id.to_s
      assigns(:appointment).should eq(appointment)
    end

    it "should error if the current_user isn't a trainer" do
      user = FactoryGirl.create(:user)
      appointment = FactoryGirl.create(:appointment, trainer: user)
      get :edit, :id => appointment.id.to_s
      flash.should_not be_nil
      flash[:error].should_not be_nil
    end

    it "should redirect if the current user isn't a trainer" do
      user = FactoryGirl.create(:user)
      appointment = FactoryGirl.create(:appointment, trainer: user)
      get :edit, :id => appointment.id.to_s
      response.should redirect_to(root_path)
    end
  end

  describe "PUT update" do
    before(:each) do
      @user.stub(:trainer?).and_return(true)
    end

    describe "with valid params" do
      it "updates the requested appointment" do
        appointment = FactoryGirl.create(:appointment, trainer: @user)
        # Assuming there are no other appointments in the database, this
        # specifies that the appointment created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        Appointment.any_instance.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => appointment.id, :appointment => {'these' => 'params'}
      end

      it "assigns the requested appointment as @appointment" do
        appointment = FactoryGirl.create(:appointment, trainer: @user)
        put :update, :id => appointment.id, :appointment => valid_attributes
        assigns(:appointment).should eq(appointment)
      end

      it "redirects to the appointment" do
        appointment = FactoryGirl.create(:appointment, trainer: @user)
        put :update, :id => appointment.id, :appointment => valid_attributes
        response.should redirect_to(appointment.user)
      end
    end

    describe "with invalid params" do
      it "assigns the appointment as @appointment" do
        appointment = FactoryGirl.create(:appointment, trainer: @user)
        # Trigger the behavior that occurs when invalid params are submitted
        Appointment.any_instance.stub(:save).and_return(false)
        put :update, :id => appointment.id.to_s, :appointment => {}
        assigns(:appointment).should eq(appointment)
      end

      it "re-renders the 'edit' template" do
        appointment = FactoryGirl.create(:appointment, trainer: @user)
        # Trigger the behavior that occurs when invalid params are submitted
        Appointment.any_instance.stub(:save).and_return(false)
        put :update, :id => appointment.id, :appointment => {}
        response.should render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    before(:each) do
      @user.stub(:trainer?).and_return(true)
    end

    it "destroys the requested appointment" do
      appointment = FactoryGirl.create(:appointment, trainer: @user)
      expect {
        delete :destroy, :id => appointment.id.to_s
      }.to change(Appointment, :count).by(-1)
    end

    it "redirects to the appointments list" do
      appointment = FactoryGirl.create(:appointment, trainer: @user)
      delete :destroy, :id => appointment.id.to_s
      response.should redirect_to(appointments_url)
    end
  end
end
