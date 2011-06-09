# require 'spec_helper'
#
# describe InstancesController do
#   context "when viewing the instances index" do
#     before { get :index, :taxonomy_id => Factory(:taxonomy).id }
#     it { should respond_with(:success) }
#     it { should render_template(:index) }
#   end
#
#   context "when viewing the new instance form" do
#     before { get :new, :taxonomy_id => Factory(:taxonomy).id }
#     it { should respond_with(:success) }
#     it { should render_template(:new) }
#   end
#
#   context "when viewing an instance" do
#     before {
#       taxonomy = Factory(:taxonomy)
#       get :show,
#         :taxonomy_id => taxonomy,
#         :id          => taxonomy.instances.first.id
#     }
#     it { should respond_with(:success) }
#     it { should render_template(:show) }
#   end
#
#   context "when viewing the edit instance form" do
#     before {
#       taxonomy = Factory(:taxonomy)
#       get :edit,
#         :taxonomy_id => taxonomy,
#         :id          => taxonomy.instances.first.id
#     }
#     it { should respond_with(:success) }
#     it { should render_template(:new) }
#   end
#
#   context "when viewing the delete instance form" do
#     before {
#       taxonomy = Factory(:taxonomy)
#       get :delete,
#         :taxonomy_id => taxonomy,
#         :id          => taxonomy.instances.first.id
#     }
#     it { should respond_with(:success) }
#     it { should render_template(:edit) }
#   end
#
#   context "when creating a new instance, with valid input" do
#     before {
#       post :create,
#         :taxonomy_id => Factory(:taxonomy),
#         :instance    => Factory.attributes_for(:instance)
#     }
#     it { should respond_with(:redirect) }
#   end
#
#   context "when creating a new instance, with invalid input" do
#     before {
#       post :create,
#         :taxonomy_id => Factory(:taxonomy),
#         :instance    => {}
#     }
#     it { should respond_with(:success) }
#     it { should render_template(:new) }
#   end
#
#   context "when updating an existing instance, with valid input" do
#     before {
#       taxonomy = Factory(:taxonomy)
#       put :update,
#         :taxonomy => taxonomy.id,
#         :id       => taxonomy.instances.first.id,
#         :instance => Factory.attributes_for(:instance)
#     }
#     it { should respond_with(:redirect) }
#   end
#
#   context "when updating an existing instance, with invalid input" do
#     before {
#       taxonomy = Factory(:taxonomy)
#       put :update,
#         :taxonomy => taxonomy.id,
#         :id       => taxonomy.instances.first.id,
#         :instance => { :title => '' }
#     }
#     it { should respond_with(:success) }
#     it { should render_template(:edit) }
#   end
#
#   context "when deleting an instance via the #destroy action" do
#     before { delete :destroy, :id => Factory(:taxonomy).id }
#     it { should respond_with(:redirect) }
#   end
#
#   context "when deleting an instance via the #delete action" do
#     before { delete :delete, :id => Factory(:taxonomy).id }
#     it { should respond_with(:redirect) }
#   end
# end