import SwiftUI
import SwiftUSDAFoodDataCentral
import SwiftUSDAFoodDataCentralModels

struct ContentView: View {
  enum Constants {
    /// Foods requested per page, and read per Load more.
    static let batchSize = 25
  }

  @State private var apiKey = ""
  @State private var client: FoodDataCentralClient?
  @State private var foods: [SearchResultFood] = []
  // Bumped on every reset so a superseded load cannot write over a newer search.
  @State private var generation = 0
  @State private var isLoading = false
  @State private var iterator: FoodSearchItemSequence.Iterator?
  @State private var loadTask: Task<Void, Never>?
  @State private var message = "Enter your api.data.gov key and search terms."
  @State private var query = ""

  var body: some View {
    NavigationStack {
      Form {
        Section("Search") {
          SecureField("api.data.gov API key", text: $apiKey)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .privacySensitive()
            .accessibilityIdentifier("apiKey")
          TextField("Search terms, such as cheddar cheese", text: $query)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .onSubmit(search)
            .accessibilityIdentifier("searchTerms")
          Button("Search", action: search)
            .disabled(isLoading)
            .accessibilityIdentifier("searchButton")
        }

        Section {
          if isLoading {
            ProgressView("Loading foods")
            Button("Cancel") { loadTask?.cancel() }
          } else if iterator != nil {
            Button("Load more", action: loadMore)
              .accessibilityIdentifier("loadMore")
          }
          Text(message)
            .accessibilityIdentifier("searchStatus")
        }

        if !foods.isEmpty {
          Section("Foods") {
            // Offsets keep a food that a later page repeats; FoodData Central does not snapshot a
            // search across pages.
            ForEach(Array(foods.enumerated()), id: \.offset) { _, food in
              NavigationLink(value: food.fdcID) {
                SearchResultRow(food: food)
              }
            }
          }
        }

        Section {
          Text(
            "Your key stays in memory and is sent only to FoodData Central in the X-Api-Key header. This demo does not save it."
          )
          Text(
            "Load more reads one page of \(Constants.batchSize) foods. Results can repeat or shift between pages."
          )
          Text("Data: USDA FoodData Central, public domain (CC0 1.0).")
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
      }
      .navigationTitle("FoodData Central")
      .navigationDestination(for: FoodID.self) { id in
        if let client {
          FoodDetailView(client: client, id: id)
        } else {
          Text("Search again to open this food.")
        }
      }
      .onChange(of: apiKey) { reset() }
      .onChange(of: query) { reset() }
      .onDisappear { loadTask?.cancel() }
    }
  }

  private func reset() {
    loadTask?.cancel()
    loadTask = nil
    generation += 1
    client = nil
    foods = []
    isLoading = false
    iterator = nil
    message = "Enter your api.data.gov key and search terms."
  }

  private func search() {
    reset()
    let configuration: FoodDataCentralConfiguration
    do throws(FoodDataCentralError) {
      configuration = try FoodDataCentralConfiguration(apiKey: apiKey)
    } catch {
      message = ErrorDescription.text(for: error)
      return
    }
    let searchQuery: FoodSearchQuery
    do throws(FoodDataCentralValidationError) {
      searchQuery = try FoodSearchQuery(query, pageSize: Constants.batchSize)
    } catch {
      message = ErrorDescription.text(for: error)
      return
    }
    let client = FoodDataCentralClient(configuration: configuration)
    self.client = client
    iterator = client.foods(matching: searchQuery).makeAsyncIterator()
    loadMore()
  }

  private func loadMore() {
    guard !isLoading, var current = iterator else { return }
    let token = generation
    isLoading = true
    message = foods.isEmpty ? "Searching." : "Loading more foods."
    loadTask = Task {
      var batch: [SearchResultFood] = []
      var finished = false
      var failure: FoodDataCentralError?
      do throws(FoodDataCentralError) {
        while batch.count < Constants.batchSize {
          guard let food = try await current.next() else {
            finished = true
            break
          }
          batch.append(food)
        }
      } catch {
        failure = error
      }
      guard token == generation else { return }
      isLoading = false
      loadTask = nil
      foods.append(contentsOf: batch)
      if failure != nil, Task.isCancelled {
        // Cancelling ends the traversal like any failure, so the search stops here; search again
        // to start over. The foods already loaded stay.
        iterator = nil
        message = "Search cancelled."
      } else if let failure {
        // A failed iterator ends its traversal, so the search cannot continue.
        iterator = nil
        message = ErrorDescription.text(for: failure)
      } else if finished {
        iterator = nil
        message =
          foods.isEmpty
          ? "No foods matched this search."
          : "Showing \(foods.count) foods. All matching foods are loaded."
      } else {
        iterator = current
        message = "Showing \(foods.count) foods."
      }
    }
  }
}

/// One search result as FoodData Central returned it.
struct SearchResultRow: View {
  let food: SearchResultFood

  var body: some View {
    VStack(alignment: .leading) {
      Text(food.description)
        .fixedSize(horizontal: false, vertical: true)
      Text(details)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }

  private var details: String {
    [food.dataType?.rawValue, food.brandOwner, "FDC ID \(food.fdcID.rawValue)"]
      .compactMap { $0 }
      .filter { !$0.isEmpty }
      .joined(separator: " · ")
  }
}

#Preview {
  ContentView()
}
