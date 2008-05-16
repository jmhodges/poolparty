class Object
  def alias_method(new_id, original_id)
    original = self.method(original_id).to_proc
    define_method(new_id){|*args| original.call(*args)}
  end
  def returning(receiver)
    yield receiver
    receiver
  end
end