class TasksController < ApplicationController
    def index
        @tasks = Task.all
    end

    def show
        @task = Task.find(params[:id])
    end

    def new
        @task = Task.new
    end

    def create
        @task = Task.new(task_params)

        @task.num = Task.all.count + 1
        @task.user = "Arsh"

        puts @task
        if @task.save
            redirect_to @task
        else
            render 'new'
        end
    end

    def edit
        @task = Task.find(params[:id])
    end

    def update
        @task = Task.find(params[:id])

        if @task.update(task_params)
            redirect_to @task
        else
            render 'edit'
        end
    end

    def destroy
        @task = Task.find(params[:id])

        Task.all.each do |task|
            puts task.num
            if task.num > @task.num
                task.update(num: task.num - 1)
            end
        end

        # Task.where(["num > ?", @task.num]).each do |task|
        #     task.update(num: task.num - 1)
        # end

        @task.destroy

        redirect_to tasks_path
    end

    private def task_params
        params.require(:task).permit(:tag, :date, :description)
    end

end
