# encoding: utf-8
module Jobit
  class Storage

    def self.all_files
      Dir.mkdir(Jobit::Job.jobs_path) unless Dir.exist?(Jobit::Job.jobs_path)
      arr = Dir.glob("#{Jobit::Job.jobs_path}/*").find_all { |x| File.file? x }
      arr.sort
    end

    def self.destroy_all
      for file_name in self.all_files
        File.delete(file_name)
      end
    end

    def self.all
      result = []

      for file_name in self.all_files
        obj = get_data_from_file(file_name)
        result << Jobby.new(obj)
      end

      result
    end

    def self.find(id)
      file_name = self.make_file_name(id)
      return nil unless File.exist?(file_name)

      obj = get_data_from_file(file_name)
      Jobby.new(obj)
    end


    def self.find_by_name(name)

      result = nil

      for file_name in self.all_files
        obj = get_data_from_file(file_name)
        next if obj.nil?
        if obj.name == name
          result = Jobby.new(obj)
          break
        end
      end

      result
    end

    def self.where(search)
      search_hash = {:name => search}
      search_hash = search if search.is_a?(Hash)

      result = []

      for file_name in self.all_files
        obj = get_data_from_file(file_name)
        for key, val in search_hash
          next unless obj.respond_to?(key)
          result << Jobby.new(obj) if obj[key] == val
        end
      end

      result
    end

    def self.destroy(file)
      file_name = self.make_file_name(file)
      return false unless File.exist?(file_name)
      File.delete(file_name)
    end

    def self.create(file, content)
      Dir.mkdir(Jobit::Job.jobs_path) unless Dir.exist?(Jobit::Job.jobs_path)
      file_name = self.make_file_name(file)
      data = Marshal.dump(content.to_hash)
      File.open(file_name, 'w+b') { |f| f.write(data) }
      true
    end


    def self.update(file, content)
      file_name = self.make_file_name(file)
      return false unless File.exist?(file_name)
      File.open(file_name, 'w+b') { |f| f.write(Marshal.dump(content.to_hash)) }
      true
    end

    private

    def self.get_data_from_file(file_name)
      begin
        file = File.open(file_name)
        obj = Marshal.load(file).to_struct
      rescue
        return nil
      ensure
        file.close
      end
      obj
    end

    def self.make_file_name(file)
      File.join(Jobit::Job.jobs_path, file.to_s)
    end


  end
end

class Hash
  def to_struct
    Struct.new(*keys).new(*values)
  end
end

class Struct
  def to_hash
    Hash[*members.zip(values).flatten]
  end
end
