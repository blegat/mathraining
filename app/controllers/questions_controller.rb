#encoding: utf-8
class QuestionsController < ApplicationController

  ########## PARTIE PRIVEE ##########
  private

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
      flash[:info] = "#{class_name} déjà le plus #{name} possible."
    else
      if (not x.nil?) and (y.nil? or fun.call(x, y))
        other = exercise2
      else
        other = qcm2
      end
      swap_position(subject, other)
      flash[:success] = "#{class_name} déplacé vers le #{name}."
    end
    redirect_to chapter_path(subject.chapter, :type => type, :which => subject.id)
  end

  def swap_position(a, b)
    x = a.position
    a.position = b.position
    b.position = x
    a.save
    b.save
  end

end
