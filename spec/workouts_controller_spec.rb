require 'spec_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator.  If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails.  There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.
#
# Compared to earlier versions of this generator, there is very limited use of
# stubs and message expectations in this spec.  Stubs are only used when there
# is no simpler way to get a handle on the object needed for the example.
# Message expectations are only used when there is no simpler way to specify
# that an instance is receiving a specific message.

describe WorkoutsController do
  login_user

  # This should return the minimal set of attributes required to create a valid
  # Workout. As you add validations to Workout, be sure to
  # update the return value of this method accordingly.

  #before(:each) do
    #@workout.user 
  #end

  def valid_attributes
    FactoryGirl.attributes_for(:workout)
  end

  describe "GET index" do
    it "assigns all workouts as @workouts" do
      workout = FactoryGirl.create(:workout, user: @user)
      get :index
      assigns(:workouts).should eq([workout])
    end

    it "assigns all the requested workouts as @workouts" do
      user = FactoryGirl.create(:user)
      workout = FactoryGirl.create(:workout, user: user)
      workout_current_user = FactoryGirl.create(:workout, user: @user)
      get :index
      assigns(:workouts).should_not include(workout)
    end
  end

  describe "GET show" do
    it "assigns the requested workout as @workout" do
      workout = FactoryGirl.create(:workout, user: @user)
      get :show, :id => workout.id.to_s
      assigns(:workout).should eq(workout)
    end
  end

  describe "GET new" do
    it "assigns a new workout as @workout" do
      get :new
      assigns(:workout).should be_a_new(Workout)
    end
  end

  describe "GET edit" do
    it "assigns the requested workout as @workout" do
      workout = FactoryGirl.create(:workout, user: @user)
      get :edit, :id => workout.id.to_s
      assigns(:workout).should eq(workout)
    end

    it "should error if the current_user doesn't own the workout" do
      user = FactoryGirl.create(:user)
      workout = FactoryGirl.create(:workout, user: user)
      get :edit, :id => workout.id.to_s
      flash.should_not be_nil
    end

    it "should redirect if the current user doesn't own the workout" do
      user = FactoryGirl.create(:user)
      workout = FactoryGirl.create(:workout, user: user)
      get :edit, :id => workout.id.to_s
      response.should redirect_to(root_path)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new Workout" do
        expect {
          post :create, :workout => valid_attributes
        }.to change(Workout, :count).by(1)
      end

      it "assigns a newly created workout as @workout" do
        post :create, :workout => valid_attributes
        assigns(:workout).should be_a(Workout)
        assigns(:workout).should be_persisted
      end

      it "redirects to the created workout" do
        post :create, :workout => valid_attributes
        response.should redirect_to(Workout.last)
      end
    end

    describe "as a trainer" do
      before(:each) do
        controller.stub!(:current_user).and_return(@user)
        @user.stub(:trainer?).and_return(true)
        @user.stub(:plan).and_return(FactoryGirl.create :plan, client_slots: 10)
      end

      describe "allows me to create a workout for a client" do
        it "should only allow me to create workouts for my own clients" do
          client = FactoryGirl.create(:user)
          post :create, :workout => valid_attributes, :client_id => client.id
          assigns(:workout).user_id.should_not eql(client.id)
        end

        it "should create a workout for that client/user" do
          client = FactoryGirl.create(:user)
          client.add_trainer(@user)
          @user.reload
          post :create, :workout => valid_attributes, :client_id => client.id
          assigns(:workout).user_id.should eql(client.id)
        end

        it "should redirect to that client page" do
          client = FactoryGirl.create(:user)
          client.add_trainer(@user)
          @user.reload
          post :create, :workout => valid_attributes, :client_id => client.id
          response.should redirect_to client_workouts_path(client)
        end

        it "should make that workout private" do
          client = FactoryGirl.create(:user)
          client.add_trainer(@user)
          post :create, :workout => valid_attributes, :client_id => client.id
        end
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved workout as @workout" do
        # Trigger the behavior that occurs when invalid params are submitted
        Workout.any_instance.stub(:save).and_return(false)
        post :create, :workout => {}
        assigns(:workout).should be_a_new(Workout)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        Workout.any_instance.stub(:save).and_return(false)
        post :create, :workout => {}
        response.should render_template("new")
      end
    end
  end

  describe "PUT update" do
    describe "with actions params" do
      it "should allow one to subscribe" do
        user = FactoryGirl.create(:user)
        workout = FactoryGirl.create(:workout, user: user)
        Workout.any_instance.should_receive(:add_subscriber).with(@user)
        put :subscribe, :id => workout.id, :workout => valid_attributes
      end

      it "should allow one to unsubscribe" do
        user = FactoryGirl.create(:user)
        workout = FactoryGirl.create(:workout, user: user)
        Workout.any_instance.should_receive(:remove_subscriber).with(@user)
        put :unsubscribe, :id => workout.id, :workout => valid_attributes
      end
    end

    describe "with valid params" do
      it "updates the requested workout" do
        workout = FactoryGirl.create(:workout, user: @user)
        # Assuming there are no other workouts in the database, this
        # specifies that the Workout created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        Workout.any_instance.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => workout.id, :workout => {'these' => 'params'}
      end

      it "assigns the requested workout as @workout" do
        workout = FactoryGirl.create(:workout, user: @user)
        put :update, :id => workout.id, :workout => valid_attributes
        assigns(:workout).should eq(workout)
      end

      it "redirects to the workout" do
        workout = FactoryGirl.create(:workout, user: @user)
        put :update, :id => workout.id, :workout => valid_attributes
        response.should redirect_to(workout)
      end
    end

    describe "with invalid params" do
      it "assigns the workout as @workout" do
        workout = FactoryGirl.create(:workout, user: @user)
        # Trigger the behavior that occurs when invalid params are submitted
        Workout.any_instance.stub(:save).and_return(false)
        put :update, :id => workout.id.to_s, :workout => {}
        assigns(:workout).should eq(workout)
      end

      it "re-renders the 'edit' template" do
        workout = FactoryGirl.create(:workout, user: @user)
        # Trigger the behavior that occurs when invalid params are submitted
        Workout.any_instance.stub(:save).and_return(false)
        put :update, :id => workout.id, :workout => {}
        response.should render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested workout" do
      workout = FactoryGirl.create(:workout, user: @user)
      expect {
        delete :destroy, :id => workout.id.to_s
      }.to change(Workout, :count).by(-1)
    end

    it "redirects to the workouts list" do
      workout = FactoryGirl.create(:workout, user: @user)
      delete :destroy, :id => workout.id.to_s
      response.should redirect_to(workouts_url)
    end
  end

end
