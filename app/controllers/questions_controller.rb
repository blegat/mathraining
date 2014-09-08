#encoding: utf-8
class QuestionsController < ApplicationController

  def order_op(haut, exercice, subject)
    if haut
      sign = '<'
      fun = lambda { |x, y| x > y }
      name = 'haut'
    else
      sign = '>'
      fun = lambda { |x, y| x < y }
      name = 'bas'
    end
    if exercice
      type = 2
      class_name = "Exercice"
    else
      type = 3
      class_name = "QCM"
    end
    x = nil
    if subject.chapter.exercises.exists?(["position #{sign} ?", subject.position])
      if haut
        exercise2 = subject.chapter.exercises.where("position #{sign} ?", subject.position).order('position').reverse_order.first
      else
        exercise2 = subject.chapter.exercises.where("position #{sign} ?", subject.position).order('position').first
      end
      x = exercise2.position
    end
    y = nil
    if subject.chapter.qcms.exists?(["position #{sign} ?", subject.position])
      if haut
        qcm2 = subject.chapter.qcms.where("position #{sign} ?", subject.position).order('position').reverse_order.first
      else
        qcm2 = subject.chapter.qcms.where("position #{sign} ?", subject.position).order('position').first
      end
      y = qcm2.position
    end
    if x.nil? and y.nil?
      flash[:notice] = "#{class_name} déjà le plus #{name} possible."
    else
      if (not x.nil?) and (y.nil? or fun.call(x, y))
        other = exercise2
      else
        other = qcm2
      end
      err = swap_position(subject, other)
      if err.nil?
        flash[:success] = "#{class_name} déplacé vers le #{name}."
      else
        flash[:danger] = err
      end
    end
    redirect_to chapter_path(subject.chapter, :type => type, :which => subject.id)
  end

  private

  def swap_position(a, b)
    err = nil
    Qcm.transaction do
      x = a.position
      a.position = b.position
      b.position = x
      a.save(validate: false)
      b.save(validate: false)
      unless a.valid? and b.valid?
        erra = get_errors(a)
        errb = get_errors(b)
        if erra.nil?
          if errb.nil?
            err = "Quelque chose a mal tourné."
          else
            err = "#{errb} pour #{b.title}"
          end
        else
          # if a is not valid b.valid? is not executed
          err = "#{erra} pour #{a.title}"
        end
        raise ActiveRecord::Rollback
      end
    end
    return err
  end

end
