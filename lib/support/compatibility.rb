# 1.9 adds realpath to resolve symlinks; 1.8 doesn't
# have this method, so we add it so we get resolved symlinks
# and compatibility
unless File.respond_to? :realpath
  class File
    def self.realpath path
      return realpath(File.readlink(path)) if symlink?(path)
      path
    end
  end
end
