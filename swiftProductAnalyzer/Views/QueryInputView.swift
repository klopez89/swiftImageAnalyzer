import SwiftUI

struct QueryInputView: View {
    @ObservedObject var viewModel: ContentViewModel
    @State private var showingFileImporter = false

    var body: some View {
        VStack(spacing: 0) {
            // Display staged image thumbnails if any
            if !viewModel.stagedProductImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.stagedProductImages) { productImage in
                            ZStack(alignment: .topTrailing) {
                                Image(nsImage: productImage.image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50)
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 5)
                                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                    )

                                Button(action: {
                                    viewModel.removeStagedImage(image: productImage)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                        .background(Circle().fill(Color.white.opacity(0.7)))
                                        .font(.title3) // Adjust size if needed
                                }
                                .buttonStyle(.borderless)
                                .offset(x: 5, y: -5) // Adjust offset for precise placement
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .frame(height: 65) // Adjust height as needed
                Divider()
            }

            // Input controls
            HStack(spacing: 12) {
                Button(action: {
                    showingFileImporter = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
                .padding(.leading)
                .fileImporter(
                    isPresented: $showingFileImporter,
                    allowedContentTypes: [.image],
                    allowsMultipleSelection: true
                ) { result in
                    switch result {
                    case .success(let urls):
                        let selectedImages = urls.compactMap { url -> NSImage? in
                            guard url.startAccessingSecurityScopedResource() else {
                                print("Permission denied for URL: \(url)")
                                return nil
                            }
                            defer { url.stopAccessingSecurityScopedResource() }
                            return NSImage(contentsOf: url)
                        }
                        viewModel.stageImages(selectedImages: selectedImages)
                    case .failure(let error):
                        print("Error picking images: \(error.localizedDescription)")
                        viewModel.errorMessage = "Failed to load images: \(error.localizedDescription)"
                    }
                }

                TextField("Ask a question about your product images...", text: $viewModel.userQuery)
                    .textFieldStyle(PlainTextFieldStyle())
                    .frame(height: 22) // Match typical macOS text field height
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(NSColor.textBackgroundColor)) // Adapts to light/dark
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .onSubmit {
                        // Only submit if the button is enabled
                        if !viewModel.stagedProductImages.isEmpty && !viewModel.userQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.isLoading {
                            viewModel.submitQuery()
                        }
                    }
                

                Button(action: {
                    viewModel.submitQuery()
                }) {
                    Image(systemName: "paperplane.fill")
                        .font(.title2)
                        .foregroundColor(viewModel.stagedProductImages.isEmpty || viewModel.userQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .accentColor)
                }
                .buttonStyle(.plain)
                .padding(.trailing)
                .disabled(viewModel.isLoading || viewModel.stagedProductImages.isEmpty || viewModel.userQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor)) // Adapts to light/dark mode
        }
    }
} 