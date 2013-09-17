desc 'Deletes all files that end with tilde (~)'
task 'tilde' do
files = []
Dir.glob('**/*~').each do |file|
File.delete(file)
files << file
end
puts "Deleted the following files: #{files.join(', ')}"
end
