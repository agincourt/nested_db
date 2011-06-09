# require 'spec_helper'
#
# describe TaxonomiesController do
#   context "when viewing the taxonomies index" do
#     before { get :index }
#     it { should respond_with(:success) }
#     it { should render_template(:index) }
#   end
#
#   context "when viewing the new taxonomy form" do
#     before { get :new }
#     it { should respond_with(:success) }
#     it { should render_template(:new) }
#   end
#
#   context "when viewing a taxonomy" do
#     before { get :show, :id => Factory(:taxonomy).id }
#     it { should respond_with(:success) }
#     it { should render_template(:show) }
#   end
#
#   context "when viewing the edit taxonomy form" do
#     before { get :edit, :id => Factory(:taxonomy).id }
#     it { should respond_with(:success) }
#     it { should render_template(:edit) }
#   end
#
#   context "when viewing the delete taxonomy form" do
#     before { get :delete, :id => Factory(:taxonomy).id }
#     it { should respond_with(:success) }
#     it { should render_template(:delete) }
#   end
#
#   context "when creating a new taxonomy, with valid input" do
#     before { post :create, :taxonomy => Factory.attributes_for(:taxonomy) }
#     it { should respond_with(:redirect) }
#   end
#
#   context "when creating a new taxonomy, with invalid input" do
#     before { post :create, :taxonomy => {} }
#     it { should respond_with(:success) }
#     it { should render_template(:new) }
#   end
#
#   context "when updating an existing taxonomy, with valid input" do
#     before {
#       put :update,
#         :id       => Factory(:taxonomy).id,
#         :taxonomy => Factory.attributes_for(:taxonomy)
#     }
#     it { should respond_with(:redirect) }
#   end
#
#   context "when updating an existing taxonomy, with invalid input" do
#     before {
#       put :update,
#         :id       => Factory(:taxonomy).id,
#         :taxonomy => { :reference => '' }
#     }
#     it { should respond_with(:success) }
#     it { should render_template(:edit) }
#   end
#
#   context "when deleting a taxonomy via the #destroy action" do
#     before { delete :destroy, :id => Factory(:taxonomy).id }
#     it { should respond_with(:redirect) }
#   end
#
#   context "when deleting a taxonomy via the #delete action" do
#     before { delete :delete, :id => Factory(:taxonomy).id }
#     it { should respond_with(:redirect) }
#   end
# end