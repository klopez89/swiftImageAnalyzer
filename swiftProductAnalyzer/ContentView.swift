//
//  ContentView.swift
//  swiftProductAnalyzer
//
//  Created by Kevin Lopez on 5/22/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("Product Image Analyzer")
                .font(.title2)
                .fontWeight(.semibold)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Material.ultraThinMaterial) // Gives a slightly translucent modern look
                .border(Color.gray.opacity(0.3), width: 0.5)

            // Main content area for chat/image analysis
            ImageAnalysisView(viewModel: viewModel)
                .frame(maxWidth: .infinity, maxHeight: .infinity) // Takes up most space

            // Loading and Error display (could be overlaid or placed contextually)
            if viewModel.isLoading {
                ProgressView("Analyzing...") // Simplified message
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.orange.opacity(0.2))
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.white)
                    .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.8))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .padding(.bottom, 5) // Give some space from input bar
                    .onTapGesture {
                        viewModel.errorMessage = nil // Allow dismissing error by tapping
                    }
            }
            
            // Query Input Area (includes staged image thumbnails and add button)
            QueryInputView(viewModel: viewModel)
        }
        .frame(minWidth: 500, idealWidth: 700, minHeight: 500, idealHeight: 700) // Adjusted min/ideal height
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
